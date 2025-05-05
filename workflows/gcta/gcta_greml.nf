/*
========================================================================================
    GCTA GREML Workflow
========================================================================================
*/

include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { RUN_REML } from '../../modules/local/gcta/run_reml'
include { GCTA_GRM } from './gcta_grm'

workflow GCTA_GREML {
    take:
    phenotypes_file     // Path to phenotypes file
    covariates_file     // Path to covariates file (optional)
    imputed_plink2_ch   // Channel with imputed PLINK2 files
    nparts_gcta         // Number of parts for GCTA GRM calculation

    main:
    // Handle empty snps_to_extract by creating an empty list channel
    def snps_to_extract_ch = Channel.of(["0", []])

    // Run GCTA GRM workflow to calculate genetic relationship matrix
    GCTA_GRM(
        imputed_plink2_ch,
        nparts_gcta,
        snps_to_extract_ch
    )

    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotypes_file,
        covariates_file
    )

    // Get the covariates files or use empty channel if not available
    // def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader.ifEmpty([])
    // def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader.ifEmpty([])

    // before RUN_REML, wrap empty queues into a single item (an empty list)
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .ifEmpty { Channel.of([]) }

    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .ifEmpty { Channel.of([]) }

    // Run REML analysis using the unrelated subjects GRM
    RUN_REML(
        GCTA_GRM.out.grm_files,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates
    )

    emit:
    reml_results = RUN_REML.out.reml_results

}
