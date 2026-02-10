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
    phenotype_pairs_ch  // Channel: tuple(phenotype1_name, phenotype1_file, is_binary1, phenotype2_name, phenotype2_file, is_binary2)
    covariates_file     // Path to covariates file (optional, use [] if not provided)
    imputed_plink2_ch   // Channel with imputed PLINK2 files
    nparts_gcta         // Number of parts for GCTA GRM calculation

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
        phenotype_pairs_ch.map { phenotype1_name, phenotype1_file, _is_binary1, phenotype2_name, phenotype2_file, _is_binary2 ->
            def pair_name = "${phenotype1_name}__${phenotype2_name}"
            tuple(phenotype1_file, phenotype2_file, covariates_file, phenotype1_name, phenotype2_name, pair_name)
        }
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV_BIVARIATE.out.covariates_quant_noheader
        .collect()
        .map { files -> files ? files[0] : [] }
    def cat_covariates = PREPARE_PHENOCOV_BIVARIATE.out.covariates_cat_noheader
        .collect()
        .map { files -> files ? files[0] : [] }

    bivariate_pairs = GCTA_GRM.out.grm_files.combine(PREPARE_PHENOCOV_BIVARIATE.out.phenotypes_file)
    grm_for_bivar = bivariate_pairs.map { grm_tuple, _pheno_tuple -> grm_tuple }
    pheno_for_bivar = bivariate_pairs.map { _grm_tuple, pheno_tuple -> pheno_tuple }

    // Run bivariate REML analysis for genetic correlation
    RUN_BIVARIATE_REML(
        grm_for_bivar,
        pheno_for_bivar,
        quant_covariates,
        cat_covariates,
    )

    emit:
    bivariate_results = RUN_BIVARIATE_REML.out.bivariate_results
    grm_files = GCTA_GRM.out.grm_files
}
