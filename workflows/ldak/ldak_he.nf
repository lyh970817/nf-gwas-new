/*
========================================================================================
    LDAK Haseman-Elston Workflow - Fast Heritability Estimation
========================================================================================

    Purpose: Run complete LDAK HE regression including kinship computation

    HE regression is a faster alternative to REML (10-100x speedup), useful for:
    - Large datasets (N > 100k)
    - Initial QC
    - Genotype error estimation

    This workflow provides backward-compatible behavior by automatically computing
    the kinship matrix before running HE regression. For workflows that need to reuse
    kinships, use LDAK_GRM and LDAK_HE_ANALYSIS separately.

    Pipeline:
    1. LDAK_GRM: Compute kinship matrices
       - Creates combined GRM, filters related individuals
       - Outputs filtered_grm (contains only unrelated individuals, 5-tuple)
    2. LDAK_HE_ANALYSIS: Run Haseman-Elston regression
       - Receives filtered_grm (5-tuple) and handles adjustment internally
       - Adjustment is done within LDAK_HE_ANALYSIS, not in LDAK_GRM

    Documentation: docs/external/ldak/01_reml-and-blup.md, doc 41
========================================================================================
*/

include { LDAK_GRM } from './ldak_grm'
include { LDAK_HE_ANALYSIS } from './ldak_he_analysis'

workflow LDAK_HE_WORKFLOW {
    take:
    imputed_plink_ch     // Channel with imputed PLINK files (bed, bim, fam)
    phenotype_file       // Path to phenotype file
    covariates_file      // Path to covariates file (optional)
    heritability_model   // Heritability model parameter (optional)

    main:
    // Compute kinship matrices (no adjustment here - done in LDAK_HE_ANALYSIS)
    LDAK_GRM(
        imputed_plink_ch,
        heritability_model
    )

    // Run HE regression using the filtered kinship
    // LDAK_HE_ANALYSIS will detect the 5-tuple and perform adjustment internally
    LDAK_HE_ANALYSIS(
        LDAK_GRM.out.filtered_grm,  // Pass filtered GRM (5-tuple, will be adjusted internally)
        [],                          // No keep_file needed (GRM already filtered)
        phenotype_file,
        covariates_file
    )

    emit:
    // Per-chromosome kinships (for potential reuse)
    ldak_grm = LDAK_GRM.out.ldak_grm
    // Combined genome-wide kinship (all individuals, before filtering)
    combined_grm = LDAK_GRM.out.combined_grm
    // List of unrelated individuals (for reference)
    filtered_list = LDAK_GRM.out.filtered_list
    // Filtered GRM (unrelated individuals only, 5-tuple)
    filtered_grm = LDAK_GRM.out.filtered_grm
    // HE heritability results
    he_results = LDAK_HE_ANALYSIS.out.he_results
}
