/*
========================================================================================
    LDAK-KVIK Workflow: Fast Mixed-Model Association Analysis
========================================================================================

    Purpose: Run complete LDAK-KVIK association analysis

    LDAK-KVIK is a fast mixed-model association analysis tool that outperforms or
    matches REGENIE and BOLT-LMM in both speed and power.

    Pipeline:
    1. KVIK_STEP1: Compute LOCO PRS using Elastic Net
       - Uses directly genotyped or thinned SNPs (~500k recommended)
       - Outputs LOCO PRS used as offset in Step 2

    2. KVIK_STEP2: Single-SNP association analysis (per-chromosome, parallel)
       - Uses full imputed data
       - Applies LOCO PRS from Step 1 as offset
       - Parallelized across chromosomes

    3. MERGE_KVIK_RESULTS: Combine per-chromosome results
    Recommendations:
    - For Step 1: Use ~500k SNPs (directly genotyped or thinned)
    - For Step 2: Run per-chromosome for parallelization
    - For binary traits: Set is_binary = true

    Documentation: docs/external/ldak-kvik/README.md
========================================================================================
*/

include { KVIK_STEP1 } from '../../modules/local/ldak/kvik_step1'
include { KVIK_STEP2 } from '../../modules/local/ldak/kvik_step2'
include { MERGE_KVIK_RESULTS } from '../../modules/local/ldak/merge_kvik_results'
include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'

workflow LDAK_KVIK_WORKFLOW {
    take:
    // Step 1 inputs: Directly genotyped or thinned SNPs
    // Can provide either:
    // - step1_plink_ch: Single merged PLINK file tuple [name, bed, bim, fam]
    // - OR imputed_plink_ch will be merged internally
    step1_plink_ch           // Channel: [name, bed, bim, fam] - Merged genotypes for Step 1

    // Step 2 inputs: Per-chromosome imputed PLINK files
    imputed_plink_ch         // Channel: [chr_num, filename, bed, bim, fam, range]

    // Phenotype and covariates
    phenotype_meta_ch        // Channel: tuple(phenotype_name, phenotype_file, is_binary)
    covariates_file          // Path to covariates file (optional - can be [])

    main:
    //=========================================================================
    // Step 1: Compute LOCO PRS using Elastic Net
    //=========================================================================
    // Uses directly genotyped or thinned SNPs for speed

    PREPARE_PHENOCOV(
        phenotype_meta_ch.map { phenotype_name, phenotypes_file, _is_binary -> tuple(phenotype_name, phenotypes_file) },
        covariates_file
    )

    quant_covariates_ch = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .toList()
        .map { files ->
            if (files) {
                return files[0]
            }
            return params.covariates_cat_columns ? [] : covariates_file
        }
    cat_covariates_ch = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .toList()
        .map { files -> files ? files[0] : [] }

    phenotype_binary_flags = phenotype_meta_ch
        .map { phenotype_name, _phenotypes_file, is_binary -> tuple(phenotype_name, is_binary) }

    phenotype_ctx_ch = PREPARE_PHENOCOV.out.phenotypes_noheader
        .join(phenotype_binary_flags, by: 0)
        .map { phenotype_name, phenotype_file_noheader, is_binary ->
        tuple(phenotype_name, phenotype_file_noheader, is_binary, 1)
    }

    step1_inputs = step1_plink_ch
        .combine(phenotype_ctx_ch)
        .map { genotype_name, bed, bim, fam, phenotype_name, phenotype_file, is_binary, mpheno ->
            tuple(genotype_name, bed, bim, fam, phenotype_file, phenotype_name, is_binary, mpheno)
        }

    KVIK_STEP1(
        step1_inputs,
        quant_covariates_ch,
        cat_covariates_ch
    )

    //=========================================================================
    // Step 2: Single-SNP Association Analysis (Per-Chromosome)
    //=========================================================================
    // Run in parallel across chromosomes using imputed data

    // Extract sample list from Step 1 fam file for consistency
    step1_keep_file = step1_plink_ch
        .map { _name, _bed, _bim, fam -> fam }
        .first()

    step1_ctx = KVIK_STEP1.out.step1_root
        .join(KVIK_STEP1.out.step1_loco_details, by: 0)
        .join(KVIK_STEP1.out.step1_loco_prs, by: 0)
        .join(KVIK_STEP1.out.step1_effects, by: 0)
        .map { phenotype_name, step1_root, step1_loco_details, step1_loco_prs, step1_effects ->
            tuple(phenotype_name, step1_root, step1_loco_details, step1_loco_prs, step1_effects)
        }

    step2_ctx = step1_ctx
        .join(PREPARE_PHENOCOV.out.phenotypes_noheader, by: 0)
        .map { phenotype_name, step1_root, step1_loco_details, step1_loco_prs, step1_effects, phenotype_file_noheader ->
            tuple(phenotype_name, phenotype_file_noheader, step1_root, step1_loco_details, step1_loco_prs, step1_effects, 1)
        }

    step2_inputs = step2_ctx
        .combine(imputed_plink_ch)
        .combine(step1_keep_file)
        .map { phenotype_name, phenotype_file, step1_root, step1_loco_details, step1_loco_prs, step1_effects, mpheno, chr_num, filename, bed, bim, fam, _range, keep_file ->
            tuple(chr_num, filename, bed, bim, fam, phenotype_file, step1_root, step1_loco_details, step1_loco_prs, step1_effects, phenotype_name, mpheno, keep_file)
        }

    KVIK_STEP2(
        step2_inputs,
        quant_covariates_ch,
        cat_covariates_ch
    )

    //=========================================================================
    // Merge Per-Chromosome Step 2 Results
    //=========================================================================

    // Collect all chromosome results
    assoc_files_by_pheno = KVIK_STEP2.out.step2_assoc.groupTuple()
    summaries_files_by_pheno = phenotype_meta_ch
        .map { phenotype_name, _phenotype_file, _is_binary -> tuple(phenotype_name, []) }
        .mix(KVIK_STEP2.out.step2_summaries.groupTuple())
        .groupTuple()
        .map { phenotype_name, summaries_lists ->
            tuple(phenotype_name, summaries_lists.flatten().findAll { it })
        }

    merge_inputs = assoc_files_by_pheno
        .join(summaries_files_by_pheno, by: 0)
        .map { phenotype_name, assoc_files, summaries_files ->
            tuple(assoc_files, summaries_files, phenotype_name)
        }

    MERGE_KVIK_RESULTS(
        merge_inputs
    )

    emit:
    // Step 1 outputs
    step1_outputs = KVIK_STEP1.out.step1_outputs
    step1_root = KVIK_STEP1.out.step1_root
    step1_loco_prs = KVIK_STEP1.out.step1_loco_prs

    // Step 2 per-chromosome results
    step2_chr_results = KVIK_STEP2.out.step2_chr_results

    // Merged Step 2 results
    merged_assoc = MERGE_KVIK_RESULTS.out.merged_assoc
    merged_summaries = MERGE_KVIK_RESULTS.out.merged_summaries
}
