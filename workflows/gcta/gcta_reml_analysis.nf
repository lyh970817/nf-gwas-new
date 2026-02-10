/*
========================================================================================
    GCTA REML Analysis Workflow - Heritability Estimation with Pre-computed GRM
========================================================================================

    Purpose: Run REML heritability analysis using pre-computed GRM files

    This workflow is designed to be used when:
    1. GRM has already been computed in a previous run
    2. You want to run heritability on the same GRM with different phenotypes
    3. You need to separate GRM computation from analysis for workflow flexibility

    Pipeline:
    1. PREPARE_PHENOCOV: Format phenotype/covariate files (remove headers, split covariates)
    2. RUN_REML: Run GCTA REML heritability estimation

    Input GRM Format:
    - grm_files: tuple [snp_group, prefix, grm.id, grm.bin, grm.N.bin]
========================================================================================
*/

include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { RUN_REML } from '../../modules/local/gcta/run_reml'

workflow GCTA_REML_ANALYSIS {
    take:
    grm_files         // Pre-computed GRM: tuple [snp_group, prefix, grm.id, grm.bin, grm.N.bin]
    phenotype_meta_ch // Channel: tuple(phenotype_name, phenotype_file, is_binary)
    covariates_file   // Path to covariates file (optional, can be [])

    main:
    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotype_meta_ch.map { phenotype_name, phenotypes_file, _is_binary -> tuple(phenotype_name, phenotypes_file) },
        covariates_file,
    )

    // Get the covariates files or use empty-list sentinel if not available
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .collect()
        .ifEmpty([[]])
        .map { files -> files ? files[0] : [] }
    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .collect()
        .ifEmpty([[]])
        .map { files -> files ? files[0] : [] }

    reml_pairs = grm_files.combine(PREPARE_PHENOCOV.out.phenotypes_noheader)
    grm_for_reml = reml_pairs.map { row -> tuple(row[0], row[1], row[2], row[3], row[4]) }
    pheno_for_reml = reml_pairs.map { row -> tuple(row[5], row[6]) }

    // Run REML analysis using the pre-computed GRM
    RUN_REML(
        grm_for_reml,
        pheno_for_reml,
        quant_covariates,
        cat_covariates,
    )

    emit:
    phenotypes_noheader = PREPARE_PHENOCOV.out.phenotypes_noheader
    covariates_quant_noheader = PREPARE_PHENOCOV.out.covariates_quant_noheader
    covariates_cat_noheader = PREPARE_PHENOCOV.out.covariates_cat_noheader
    reml_results = RUN_REML.out.reml_results
}
