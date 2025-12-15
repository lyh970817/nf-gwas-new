/*
========================================================================================
    LDAK PCGC Analysis Workflow - Binary Trait Heritability with Pre-computed Kinship
========================================================================================

    Purpose: Run LDAK PCGC regression using pre-computed kinship matrix

    This workflow is designed to be used when:
    1. Kinship has already been computed (via LDAK_GRM or separately)
    2. You want to run binary trait heritability on the same kinship with different phenotypes
    3. You need to separate kinship computation from analysis for workflow flexibility

    Note: PCGC regression requires adjusted GRM. The workflow automatically detects
    whether the input GRM is adjusted (has .grm.root file) or not, and computes
    adjustment if needed.

    IMPORTANT: Requires params.ldak_pcgc_prevalence to be set (disease prevalence 0-1)

    Pipeline:
    1. PREPARE_PHENOCOV: Format phenotype/covariate files
    2. ADJUST_GRM_LDAK: Adjust GRM for covariates (only if not pre-adjusted)
    3. LDAK_PCGC: Run PCGC regression for liability-scale heritability

    Input Format:
    - grm_input: LDAK kinship files, either:
        - Non-adjusted: tuple [prefix, bin, id, details, adjust]
        - Pre-adjusted: tuple [prefix, bin, id, details, adjust, root]
    - keep_file: Optional .keep file (use [] if GRM is already filtered)
========================================================================================
*/

include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { ADJUST_GRM_LDAK } from '../../modules/local/ldak/adjust_grm'
include { LDAK_PCGC } from '../../modules/local/ldak/ldak_pcgc'

workflow LDAK_PCGC_ANALYSIS {
    take:
    grm_input         // Pre-computed kinship (adjusted or non-adjusted)
    keep_file         // Optional .keep file (use [] if GRM is already filtered)
    phenotypes_file   // Path to phenotypes file (must be binary: 0/1 or 1/2)
    covariates_file   // Path to covariates file (optional, can be [])

    main:
    // Validate that prevalence is set for PCGC
    if (!params.ldak_pcgc_prevalence) {
        error "ERROR: --ldak_pcgc_prevalence is required when using PCGC regression. Please provide disease prevalence (0-1)."
    }

    // Prepare phenotypes and covariates files
    PREPARE_PHENOCOV(
        phenotypes_file,
        covariates_file
    )

    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader.ifEmpty([])
    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader.ifEmpty([])

    // Check if GRM is already adjusted by examining tuple size
    // Non-adjusted: [prefix, bin, id, details, adjust] = 5 elements
    // Adjusted: [prefix, bin, id, details, adjust, root] = 6 elements
    grm_input
        .branch { tuple_data ->
            adjusted: tuple_data.size() == 6
            needs_adjustment: tuple_data.size() == 5
        }
        .set { grm_branched }

    // For non-adjusted GRM, compute adjustment
    ADJUST_GRM_LDAK(
        grm_branched.needs_adjustment,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates
    )

    // Merge adjusted GRMs: pre-adjusted + newly adjusted
    grm_for_pcgc = grm_branched.adjusted.mix(ADJUST_GRM_LDAK.out.adjusted_grm)

    // Run PCGC regression for binary traits
    // If GRM is already filtered, keep_file should be [] (empty)
    LDAK_PCGC(
        grm_for_pcgc,
        keep_file,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates
    )

    emit:
    phenotypes_noheader = PREPARE_PHENOCOV.out.phenotypes_noheader
    covariates_quant_noheader = PREPARE_PHENOCOV.out.covariates_quant_noheader
    covariates_cat_noheader = PREPARE_PHENOCOV.out.covariates_cat_noheader
    pcgc_results = LDAK_PCGC.out.pcgc_results
}
