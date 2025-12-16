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

    4. KVIK_STEP3 (optional): Gene-based association testing
       - Uses LDAK-GBAT methodology
       - Requires gene annotation file

    Recommendations:
    - For Step 1: Use ~500k SNPs (directly genotyped or thinned)
    - For Step 2: Run per-chromosome for parallelization
    - For binary traits: Set is_binary = true

    Documentation: docs/external/ldak-kvik/README.md
========================================================================================
*/

include { KVIK_STEP1 } from '../../modules/local/ldak/kvik_step1'
include { KVIK_STEP2 } from '../../modules/local/ldak/kvik_step2'
include { KVIK_STEP3 } from '../../modules/local/ldak/kvik_step3'
include { MERGE_KVIK_RESULTS } from '../../modules/local/ldak/merge_kvik_results'
include { MERGE_PLINK_FILES } from '../../modules/local/merge_plink_files'
include { THIN_PREDICTORS } from '../../modules/local/ldak/thin_predictors'

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
    phenotype_file           // Path to phenotype file
    covariates_file          // Path to covariates file (optional - can be [])

    // Analysis options
    is_binary                // Boolean: true for case-control, false for quantitative
    mpheno                   // Phenotype column: 1, 2, ... or "ALL"
    phenotype_name           // String: phenotype name for output naming

    // Optional Step 3 inputs
    genefile                 // Path to gene annotation file ([] to skip Step 3)

    // Optional filtering
    extract_file             // SNP list to restrict Step 1 ([] for no restriction)

    main:
    //=========================================================================
    // Step 1: Compute LOCO PRS using Elastic Net
    //=========================================================================
    // Uses directly genotyped or thinned SNPs for speed

    KVIK_STEP1(
        step1_plink_ch,
        phenotype_file,
        covariates_file,
        phenotype_name,
        is_binary,
        mpheno,
        extract_file
    )

    //=========================================================================
    // Step 2: Single-SNP Association Analysis (Per-Chromosome)
    //=========================================================================
    // Run in parallel across chromosomes using imputed data

    // Extract sample list from Step 1 fam file for consistency
    step1_keep_file = step1_plink_ch.map { name, bed, bim, fam -> fam }

    KVIK_STEP2(
        imputed_plink_ch,
        phenotype_file,
        covariates_file,
        KVIK_STEP1.out.step1_root,
        KVIK_STEP1.out.step1_loco_details,
        KVIK_STEP1.out.step1_loco_prs,
        KVIK_STEP1.out.step1_effects,
        mpheno,
        step1_keep_file
    )

    //=========================================================================
    // Merge Per-Chromosome Step 2 Results
    //=========================================================================

    // Collect all chromosome results
    assoc_files_ch = KVIK_STEP2.out.step2_assoc.collect()
    summaries_files_ch = KVIK_STEP2.out.step2_summaries.collect()

    MERGE_KVIK_RESULTS(
        assoc_files_ch,
        summaries_files_ch,
        phenotype_name
    )

    //=========================================================================
    // Step 3: Gene-Based Analysis (Optional)
    //=========================================================================

    // Only run Step 3 if gene annotation file is provided
    if (genefile) {
        // For Step 3, we need merged PLINK files
        // Collect all chromosome PLINK files
        merged_plink_for_step3 = imputed_plink_ch
            .map { chr_num, filename, bed, bim, fam, range ->
                [bed, bim, fam]
            }
            .collect()
            .map { files ->
                def beds = files.collect { it[0] }
                def bims = files.collect { it[1] }
                def fams = files.collect { it[2] }
                [beds, bims, fams]
            }

        MERGE_PLINK_FILES(
            merged_plink_for_step3.map { it[0] }.flatten().collect(),
            merged_plink_for_step3.map { it[1] }.flatten().collect(),
            merged_plink_for_step3.map { it[2] }.flatten().collect(),
            "merged_for_step3"
        )

        KVIK_STEP3(
            MERGE_PLINK_FILES.out.merged_plink,
            genefile,
            KVIK_STEP1.out.step1_root,
            KVIK_STEP1.out.step1_loco_details,
            KVIK_STEP1.out.step1_loco_prs,
            KVIK_STEP1.out.step1_effects,
            MERGE_KVIK_RESULTS.out.merged_summaries,
            phenotype_name
        )

        step3_outputs = KVIK_STEP3.out.step3_outputs
        step3_remls_all = KVIK_STEP3.out.step3_remls_all
    } else {
        // Create empty channels if Step 3 is skipped
        step3_outputs = Channel.empty()
        step3_remls_all = Channel.empty()
    }

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

    // Step 3 results (if run)
    step3_outputs = step3_outputs
    step3_remls_all = step3_remls_all
}
