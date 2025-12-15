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
    phenotypes_file   // Path to phenotypes file
    covariates_file   // Path to covariates file (optional, can be [])

    main:
    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotypes_file,
        covariates_file,
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader

    // Run REML analysis using the pre-computed GRM
    RUN_REML(
        grm_files,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates.ifEmpty([]),
        cat_covariates.ifEmpty([]),
    )

    emit:
    phenotypes_noheader = PREPARE_PHENOCOV.out.phenotypes_noheader
    covariates_quant_noheader = PREPARE_PHENOCOV.out.covariates_quant_noheader
    covariates_cat_noheader = PREPARE_PHENOCOV.out.covariates_cat_noheader
    reml_results = RUN_REML.out.reml_results
}
