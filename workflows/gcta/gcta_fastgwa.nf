/*
========================================================================================
    GCTA FastGWA Workflow
========================================================================================
*/

include { GCTA_GRM } from './gcta_grm'
include { MAKE_BK_SPARSE } from '../../modules/local/gcta/make_bk_sparse'
include { RUN_FASTGWA_MLM } from '../../modules/local/gcta/run_fastgwa_mlm'
include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'

workflow GCTA_FASTGWA {
    take:
    imputed_plink2_ch   // Channel with imputed PLINK2 files for GRM calculation and association testing
    phenotypes_file     // Path to phenotypes file
    covariates_file     // Path to covariates file (optional)
    nparts_gcta         // Number of parts for GCTA GRM calculation
    sparse_cutoff       // Cutoff for sparse GRM (default: 0.05)

    main:
    // Create a default channel for snps_to_extract (with a single snp group "0" and no snp group files)
    def snps_to_extract_ch = Channel.of(["0", []])

    // Run GCTA GRM workflow to calculate genetic relationship matrix
    GCTA_GRM(
        imputed_plink2_ch,
        nparts_gcta,
        snps_to_extract_ch
    )

    // Create a sparse GRM using the adjusted unrelated GRM
    MAKE_BK_SPARSE(
        GCTA_GRM.out.grm_files,
        sparse_cutoff
    )

    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotypes_file,
        covariates_file
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .ifEmpty { Channel.of([]) }

    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .ifEmpty { Channel.of([]) }

    // Run FastGWA-MLM analysis for each PLINK file without combining inputs
    RUN_FASTGWA_MLM(
        imputed_plink2_ch,
        MAKE_BK_SPARSE.out.sparse_grm_files,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates
    )

    emit:
    fastgwa_results = RUN_FASTGWA_MLM.out.fastgwa_results

}
