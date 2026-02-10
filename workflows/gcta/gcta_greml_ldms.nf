/*
========================================================================================
    GCTA GREML-LDMS Workflow - Partitioned Heritability Estimation
========================================================================================

    Purpose: Run complete GREML-LDMS heritability estimation including LD-stratified GRM

    This workflow computes LD scores, segments SNPs into groups, calculates separate
    GRMs for each group, and runs multi-component REML to partition heritability
    by LD strata.

    Pipeline:
    1. GCTA_GRM_LDMS: Compute LD scores and LD-stratified GRMs
    2. GCTA_REML_LDMS_ANALYSIS: Run multi-component REML heritability estimation

    For workflows that need to reuse GRMs, use GCTA_GRM_LDMS and
    GCTA_REML_LDMS_ANALYSIS separately.
========================================================================================
*/

include { GCTA_GRM_LDMS } from './gcta_grm_ldms'
include { GCTA_REML_LDMS_ANALYSIS } from './gcta_reml_ldms_analysis'

workflow GCTA_GREML_LDMS {
    take:
    phenotype_meta_ch   // Channel: tuple(phenotype_name, phenotype_file, is_binary)
    covariates_file     // Path to covariates file (optional)
    imputed_plink2_ch   // Channel with imputed PLINK2 files (for GRM)
    imputed_plink_ch    // Channel with imputed PLINK1 files (for LD scores)
    nparts_gcta         // Number of parts for GCTA GRM calculation

    main:
    // Compute LD scores and LD-stratified GRMs
    GCTA_GRM_LDMS(
        imputed_plink2_ch,
        imputed_plink_ch,
        nparts_gcta
    )

    // Run multi-component REML analysis
    GCTA_REML_LDMS_ANALYSIS(
        GCTA_GRM_LDMS.out.mgrm_file,
        GCTA_GRM_LDMS.out.all_grm_files,
        phenotype_meta_ch,
        covariates_file,
    )

    emit:
    // LD scores per chromosome
    ld_scores = GCTA_GRM_LDMS.out.ld_scores
    // Multiple GRMs stratified by LD
    grm_files = GCTA_GRM_LDMS.out.grm_files
    // Multi-GRM file
    mgrm_file = GCTA_GRM_LDMS.out.mgrm_file
    // All GRM files collected
    all_grm_files = GCTA_GRM_LDMS.out.all_grm_files
    // REML heritability results (partitioned)
    reml_results = GCTA_REML_LDMS_ANALYSIS.out.reml_results
}
