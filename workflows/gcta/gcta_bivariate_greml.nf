/*
========================================================================================
    GCTA Bivariate GREML Workflow
========================================================================================
    Estimates genetic correlation between two traits using bivariate REML with a single GRM.

    Inputs:
    - phenotypes_file: Phenotype file with at least two phenotype columns
    - covariates_file: Covariate file (optional)
    - imputed_plink2_ch: PLINK2 genotype files
    - nparts_gcta: Number of GRM partitions for parallelization
    - phenotype1_name: Name of first phenotype column
    - phenotype2_name: Name of second phenotype column

    Outputs:
    - bivariate_results: .hsq file with genetic correlation and variance components
    - grm_files: GRM files (for reuse)
========================================================================================
*/

include { PREPARE_PHENOCOV_BIVARIATE } from '../../modules/local/gcta/prepare_phenocov_bivariate'
include { RUN_BIVARIATE_REML } from '../../modules/local/gcta/run_bivariate_reml'
include { GCTA_GRM } from './gcta_grm'

workflow GCTA_BIVARIATE_GREML {
    take:
    phenotypes_file     // Path to phenotypes file (must contain both phenotypes)
    covariates_file     // Path to covariates file (optional, use [] if not provided)
    imputed_plink2_ch   // Channel with imputed PLINK2 files
    nparts_gcta         // Number of parts for GCTA GRM calculation
    phenotype1_name     // Name of first phenotype column
    phenotype2_name     // Name of second phenotype column

    main:
    // Handle empty snps_to_extract by creating an empty list channel
    def snps_to_extract_ch = Channel.of(["0", []])

    // Run GCTA GRM workflow to calculate genetic relationship matrix
    GCTA_GRM(
        imputed_plink2_ch,
        nparts_gcta,
        snps_to_extract_ch,
        false,  // create_sparse_grm
        0.05,   // sparse_cutoff (not used)
        false   // skip_relatedness_filter
    )

    // Prepare phenotypes for bivariate analysis
    // Extracts FID, IID, phenotype1, phenotype2 in GCTA format
    PREPARE_PHENOCOV_BIVARIATE(
        phenotypes_file,
        covariates_file,
        phenotype1_name,
        phenotype2_name,
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV_BIVARIATE.out.covariates_quant_noheader
    def cat_covariates = PREPARE_PHENOCOV_BIVARIATE.out.covariates_cat_noheader

    // Run bivariate REML analysis for genetic correlation
    RUN_BIVARIATE_REML(
        GCTA_GRM.out.grm_files,
        PREPARE_PHENOCOV_BIVARIATE.out.phenotypes_file,
        quant_covariates.ifEmpty([]),
        cat_covariates.ifEmpty([]),
    )

    emit:
    bivariate_results = RUN_BIVARIATE_REML.out.bivariate_results
    grm_files = GCTA_GRM.out.grm_files
}
