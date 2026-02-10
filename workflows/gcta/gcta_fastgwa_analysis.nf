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
    phenotype_meta_ch   // Channel: tuple(phenotype_name, phenotype_file, is_binary)
    covariates_file     // Path to covariates file (optional, can be [])

    main:
    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotype_meta_ch.map { phenotype_name, phenotypes_file, _is_binary -> tuple(phenotype_name, phenotypes_file) },
        covariates_file,
    )

    // Optional covariate files: keep a non-list sentinel through channel combines
    def no_file_token = '__NO_FILE__'
    def quant_covariates_ch = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .collect()
        .ifEmpty([no_file_token])
        .map { files -> files ? files[0] : no_file_token }
    def cat_covariates_ch = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .collect()
        .ifEmpty([no_file_token])
        .map { files -> files ? files[0] : no_file_token }

    phenotype_ctx_ch = PREPARE_PHENOCOV.out.phenotypes_noheader
        .combine(quant_covariates_ch)
        .combine(cat_covariates_ch)
        .map { row ->
            def phenotype_name = row[0]
            def phenotypes_noheader = row[1]
            def qcovar_file = row.size() > 2 ? row[2] : no_file_token
            def covar_file = row.size() > 3 ? row[3] : no_file_token
            tuple(phenotype_name, phenotypes_noheader, qcovar_file, covar_file)
        }

    // Run FastGWA-MLM analysis for each PLINK file (per chromosome)
    fastgwa_inputs = phenotype_ctx_ch
        .combine(imputed_plink2_ch)
        .combine(sparse_grm_files)
        .map { row ->
            def phenotype_name = row[0]
            def phenotypes_noheader = row[1]
            def qcovar_file = row[2] == no_file_token ? [] : row[2]
            def covar_file = row[3] == no_file_token ? [] : row[3]
            def chr_num = row[4]
            def filename = row[5]
            def plink_pgen = row[6]
            def plink_psam = row[7]
            def plink_pvar = row[8]
            def range = row[9]
            def sparse_grm_id = row[10]
            def sparse_grm_sp = row[11]
            tuple(phenotype_name, chr_num, filename, plink_pgen, plink_psam, plink_pvar, range, sparse_grm_id, sparse_grm_sp, phenotypes_noheader, qcovar_file, covar_file)
        }

    RUN_FASTGWA_MLM(
        fastgwa_inputs
    )

    emit:
    phenotypes_noheader = PREPARE_PHENOCOV.out.phenotypes_noheader
    covariates_quant_noheader = PREPARE_PHENOCOV.out.covariates_quant_noheader
    covariates_cat_noheader = PREPARE_PHENOCOV.out.covariates_cat_noheader
    fastgwa_results = RUN_FASTGWA_MLM.out.fastgwa_results
}
