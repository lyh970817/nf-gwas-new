/*
========================================================================================
    GCTA FastGWA Analysis Workflow - Association Testing with Pre-computed Sparse GRM
========================================================================================

    Purpose: Run FastGWA-MLM association testing using pre-computed sparse GRM files

    This workflow is designed to be used when:
    1. Sparse GRM has already been computed in a previous run
    2. You want to run association on the same GRM with different phenotypes
    3. You need to separate GRM computation from analysis for workflow flexibility

    Pipeline:
    1. PREPARE_PHENOCOV: Format phenotype/covariate files (remove headers, split covariates)
    2. RUN_FASTGWA_MLM: Run FastGWA-MLM association testing (parallelized by chromosome)

    Input Format:
    - sparse_grm_files: Sparse GRM tuple [snp_group, prefix, sparse_grm_sp, sparse_grm_id]
    - imputed_plink2_ch: PLINK2 files for association testing
========================================================================================
*/

include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { RUN_FASTGWA_MLM } from '../../modules/local/gcta/run_fastgwa_mlm'

workflow GCTA_FASTGWA_ANALYSIS {
    take:
    imputed_plink2_ch   // Channel with imputed PLINK2 files for association testing
    sparse_grm_files    // Pre-computed sparse GRM: tuple [snp_group, prefix, sparse_grm_sp, sparse_grm_id]
    phenotypes_file     // Path to phenotypes file
    covariates_file     // Path to covariates file (optional, can be [])

    main:
    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotypes_file,
        covariates_file,
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader

    // Run FastGWA-MLM analysis for each PLINK file (per chromosome)
    RUN_FASTGWA_MLM(
        imputed_plink2_ch,
        sparse_grm_files,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates.ifEmpty([]),
        cat_covariates.ifEmpty([]),
    )

    emit:
    phenotypes_noheader = PREPARE_PHENOCOV.out.phenotypes_noheader
    covariates_quant_noheader = PREPARE_PHENOCOV.out.covariates_quant_noheader
    covariates_cat_noheader = PREPARE_PHENOCOV.out.covariates_cat_noheader
    fastgwa_results = RUN_FASTGWA_MLM.out.fastgwa_results
}
