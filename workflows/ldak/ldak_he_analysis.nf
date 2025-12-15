/*
========================================================================================
    LDAK HE Analysis Workflow - Haseman-Elston Regression with Pre-computed Kinship
========================================================================================

    Purpose: Run LDAK HE regression using pre-computed kinship matrix

    This workflow is designed to be used when:
    1. Kinship has already been computed (via LDAK_GRM or separately)
    2. You want to run fast heritability on the same kinship with different phenotypes
    3. You need to separate kinship computation from analysis for workflow flexibility

    Note: HE regression requires adjusted GRM. The workflow automatically detects
    whether the input GRM is adjusted (has .grm.root file) or not, and computes
    adjustment if needed.

    Pipeline:
    1. PREPARE_PHENOCOV: Format phenotype/covariate files
    2. ADJUST_GRM_LDAK: Adjust GRM for covariates (only if not pre-adjusted)
    3. LDAK_HE: Run Haseman-Elston regression

    Input Format:
    - grm_input: LDAK kinship files, either:
        - Non-adjusted: tuple [prefix, bin, id, details, adjust]
        - Pre-adjusted: tuple [prefix, bin, id, details, adjust, root]
    - keep_file: Optional .keep file (use [] if GRM is already filtered)
========================================================================================
*/

include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { ADJUST_GRM_LDAK } from '../../modules/local/ldak/adjust_grm'
include { LDAK_HE } from '../../modules/local/ldak/ldak_he'

workflow LDAK_HE_ANALYSIS {
    take:
    grm_input         // Pre-computed kinship (adjusted or non-adjusted)
    keep_file         // Optional .keep file (use [] if GRM is already filtered)
    phenotypes_file   // Path to phenotypes file
    covariates_file   // Path to covariates file (optional, can be [])

    main:
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
    grm_for_he = grm_branched.adjusted.mix(ADJUST_GRM_LDAK.out.adjusted_grm)

    // Get subset parameters (optional for batch error estimation)
    def subset_prefix = params.ldak_he_subset_prefix ?: ""
    def subset_number = params.ldak_he_subset_number ?: 0

    // Run HE regression
    // If GRM is already filtered, keep_file should be [] (empty)
    LDAK_HE(
        grm_for_he,
        keep_file,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates,
        subset_prefix,
        subset_number
    )

    emit:
    phenotypes_noheader = PREPARE_PHENOCOV.out.phenotypes_noheader
    covariates_quant_noheader = PREPARE_PHENOCOV.out.covariates_quant_noheader
    covariates_cat_noheader = PREPARE_PHENOCOV.out.covariates_cat_noheader
    he_results = LDAK_HE.out.he_results
}
