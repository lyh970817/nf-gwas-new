/*
========================================================================================
    LDAK PCGC Workflow - Binary Trait Liability-Scale Heritability
========================================================================================

    Purpose: Run complete LDAK PCGC regression including kinship computation

    PCGC regression estimates heritability on the liability scale for binary traits
    (case-control studies). It is more accurate than standard REML for case-control
    data because it accounts for ascertainment bias.

    IMPORTANT: Requires params.ldak_pcgc_prevalence to be set (disease prevalence 0-1)

    This workflow provides backward-compatible behavior by automatically computing
    the kinship matrix before running PCGC regression. For workflows that need to reuse
    kinships, use LDAK_GRM and LDAK_PCGC_ANALYSIS separately.

    Pipeline:
    1. LDAK_GRM: Compute kinship matrices
       - Creates combined GRM, filters related individuals
       - Outputs filtered_grm (contains only unrelated individuals, 5-tuple)
    2. LDAK_PCGC_ANALYSIS: Run PCGC regression
       - Receives filtered_grm (5-tuple) and handles adjustment internally
       - Adjustment is done within LDAK_PCGC_ANALYSIS, not in LDAK_GRM

    Documentation: docs/external/ldak/06_pcgc-regression.md
========================================================================================
*/

include { LDAK_GRM } from './ldak_grm'
include { LDAK_PCGC_ANALYSIS } from './ldak_pcgc_analysis'

workflow LDAK_PCGC_WORKFLOW {
    take:
    imputed_plink_ch     // Channel with imputed PLINK files (bed, bim, fam)
    phenotype_file       // Path to phenotype file (must be binary: 0/1 or 1/2)
    covariates_file      // Path to covariates file (optional)
    heritability_model   // Heritability model parameter (optional)

    main:
    // Validate that prevalence is set for PCGC
    if (!params.ldak_pcgc_prevalence) {
        error "ERROR: --ldak_pcgc_prevalence is required when using PCGC regression. Please provide disease prevalence (0-1)."
    }

    // Compute kinship matrices (no adjustment here - done in LDAK_PCGC_ANALYSIS)
    LDAK_GRM(
        imputed_plink_ch,
        heritability_model
    )

    // Run PCGC regression using the filtered kinship
    // LDAK_PCGC_ANALYSIS will detect the 5-tuple and perform adjustment internally
    LDAK_PCGC_ANALYSIS(
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
    // PCGC heritability results
    pcgc_results = LDAK_PCGC_ANALYSIS.out.pcgc_results
}
