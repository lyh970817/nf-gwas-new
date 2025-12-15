/*
========================================================================================
    GCTA GREML Workflow - Complete Heritability Estimation Pipeline
========================================================================================

    Purpose: Run complete GREML heritability estimation including GRM computation

    This workflow provides backward-compatible behavior by automatically computing
    the GRM before running heritability analysis. For workflows that need to reuse
    GRMs, use GCTA_GRM and GCTA_REML_ANALYSIS separately.

    Pipeline:
    1. GCTA_GRM: Compute genetic relationship matrix
    2. GCTA_REML_ANALYSIS: Run REML heritability estimation
========================================================================================
*/

include { GCTA_GRM } from './gcta_grm'
include { GCTA_REML_ANALYSIS } from './gcta_reml_analysis'

workflow GCTA_GREML {
    take:
    phenotypes_file     // Path to phenotypes file
    covariates_file     // Path to covariates file (optional)
    imputed_plink2_ch   // Channel with imputed PLINK2 files
    nparts_gcta         // Number of parts for GCTA GRM calculation

    main:
    // Handle empty snps_to_extract by creating a default channel (single group "0")
    def snps_to_extract_ch = Channel.of(["0", []])

    // Run GCTA GRM workflow to calculate genetic relationship matrix
    // Note: create_sparse_grm=false for standard GREML
    GCTA_GRM(
        imputed_plink2_ch,
        nparts_gcta,
        snps_to_extract_ch,
        false,  // create_sparse_grm
        0.05,   // sparse_cutoff (not used)
        false   // skip_relatedness_filter
    )

    // Run REML analysis using the computed GRM
    GCTA_REML_ANALYSIS(
        GCTA_GRM.out.grm_files,
        phenotypes_file,
        covariates_file,
    )

    emit:
    // GRM files (for potential reuse)
    grm_files = GCTA_GRM.out.grm_files
    // REML heritability results
    reml_results = GCTA_REML_ANALYSIS.out.reml_results
}
