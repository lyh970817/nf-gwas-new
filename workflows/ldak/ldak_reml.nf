/*
========================================================================================
    LDAK REML Workflow - Complete Heritability Estimation Pipeline
========================================================================================

    Purpose: Run complete LDAK REML heritability estimation including kinship computation

    This workflow provides backward-compatible behavior by automatically computing
    the kinship matrix before running heritability analysis. For workflows that need
    to reuse kinships, use LDAK_GRM and LDAK_REML_ANALYSIS separately.

    Pipeline:
    1. LDAK_GRM: Compute kinship matrices (creates combined GRM, then filters related individuals)
       - Outputs filtered_grm (contains only unrelated individuals)
    2. LDAK_REML_ANALYSIS: Run REML heritability estimation
       - Uses filtered_grm directly (no --keep parameter needed)
========================================================================================
*/

include { LDAK_GRM } from './ldak_grm'
include { LDAK_REML_ANALYSIS } from './ldak_reml_analysis'

// Main workflow
workflow LDAK_REML_WORKFLOW {
    take:
    imputed_plink_ch     // Channel with imputed PLINK files (bed, bim, fam)
    phenotype_file       // Path to phenotype file
    covariates_file      // Path to covariates file (optional)
    heritability_model   // Heritability model parameter (optional)

    main:
    // Compute kinship matrices
    LDAK_GRM(
        imputed_plink_ch,
        heritability_model
    )

    // Run REML analysis using the filtered kinship (unrelated individuals only)
    // No keep_file needed since filtered_grm already excludes related individuals
    LDAK_REML_ANALYSIS(
        LDAK_GRM.out.filtered_grm,  // Use filtered GRM directly (5-tuple)
        [],                          // No keep_file needed
        phenotype_file,
        covariates_file
    )

    emit:
    // Per-chromosome kinships (for potential reuse)
    ldak_grm = LDAK_GRM.out.ldak_grm
    // Multi-GRM file
    mgrm_file = LDAK_GRM.out.mgrm_file
    // Combined genome-wide kinship (all individuals, before filtering)
    combined_grm = LDAK_GRM.out.combined_grm
    // List of unrelated individuals (for reference)
    filtered_list = LDAK_GRM.out.filtered_list
    // Filtered GRM (unrelated individuals only)
    filtered_grm = LDAK_GRM.out.filtered_grm
    // REML heritability results
    reml_results = LDAK_REML_ANALYSIS.out.reml_results
}
