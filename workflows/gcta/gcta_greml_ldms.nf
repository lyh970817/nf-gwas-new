/*
========================================================================================
    GCTA GREML-LDMS Workflow
========================================================================================
*/

include { CALCULATE_LD_SCORES } from '../../modules/local/gcta/calculate_ld_scores'
include { MERGE_SNP_GROUPS } from '../../modules/local/gcta/merge_snp_groups'
include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { MAKE_MGRM } from '../../modules/local/gcta/make_mgrm'
include { RUN_REML } from '../../modules/local/gcta/run_reml'
include { GCTA_GRM } from './gcta_grm'

workflow GCTA_GREML_LDMS {
    take:
    phenotypes_file     // Path to phenotypes file
    covariates_file     // Path to covariates file (optional)
    imputed_plink2_ch   // Channel with imputed PLINK2 files
    nparts_gcta         // Number of parts for GCTA GRM calculation

    main:

    // Calculate LD scores for each chromosome and segment SNPs into groups
    CALCULATE_LD_SCORES(
        imputed_plink2_ch
    )

    // Extract group number from the SNP group files
    // and group them by group number
    snp_group_ch =
        CALCULATE_LD_SCORES.out.snp_group_files
            .flatMap { _chr , lst ->
                /* lst.withIndex()  gives  (Path file , int idx) */
                lst.withIndex().collect { file, idx ->
                    /* idx starts at 0 → add 1 so that group numbers are 1-based */
                    tuple( idx + 1 , file )
                }
            }      // >>> one element per (group , chromosome)
            .groupTuple()

    // Merge SNP group files for each group
    MERGE_SNP_GROUPS(
        snp_group_ch
    )
    
    GCTA_GRM(
        imputed_plink2_ch,
        nparts_gcta,
        MERGE_SNP_GROUPS.out.snps_to_extract
    )
    
    // Create MGRM file containing all GRM root names
    grm_prefixes = GCTA_GRM.out.grm_files
        .map { _group, prefix, _id_file, _bin_file, _n_bin_file ->
            prefix
        }
        .collect()

    MAKE_MGRM(
        grm_prefixes
    )
    
    
    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotypes_file,
        covariates_file
    )

    // // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .ifEmpty { Channel.of([]) }

    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .ifEmpty { Channel.of([]) }

    // // Run REML analysis using the unrelated subjects GRM
    RUN_REML(
        GCTA_GRM.out.grm_adj_unrel_files,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates
    )

    // emit:
    // ld_scores = CALCULATE_LD_SCORES.out.ld_scores
    // snp_groups = MERGE_SNP_GROUPS.out.merged_snp_groups
    // reml_results = RUN_REML.out.reml_results
}
