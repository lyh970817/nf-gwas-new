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
    phenotype_meta_ch // Channel: tuple(phenotype_name, phenotype_file, is_binary)
    covariates_file   // Path to covariates file (optional, can be [])

    main:
    // Prepare phenotypes and covariates files
    PREPARE_PHENOCOV(
        phenotype_meta_ch.map { phenotype_name, phenotypes_file, _is_binary -> tuple(phenotype_name, phenotypes_file) },
        covariates_file
    )

    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .toList()
        .map { files -> files ? files[0] : [] }
    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .toList()
        .map { files -> files ? files[0] : [] }
    def all_covariates = params.covariates_columns ? params.covariates_columns.split(',').collect { it.trim() } : []
    def cat_covariates_list = params.covariates_cat_columns ? params.covariates_cat_columns.split(',').collect { it.trim() } : []
    def quant_covariates_list = all_covariates - cat_covariates_list
    def needs_adjustment = quant_covariates_list.size() > 0

    // Check if GRM is already adjusted by examining tuple size
    // Non-adjusted: [prefix, bin, id, details, adjust] = 5 elements
    // Adjusted: [prefix, bin, id, details, adjust, root] = 6 elements
    grm_with_root = grm_input.map { tuple_data ->
        tuple_data.size() == 5 ? (tuple_data + [ [] ]) : tuple_data
    }

    grm_pairs = grm_with_root.combine(PREPARE_PHENOCOV.out.phenotypes_noheader)

    grm_pairs
        .branch { row ->
            adjusted: row[5]
            needs_adjustment: !row[5]
        }
        .set { grm_branched }

    if (needs_adjustment) {
        // For non-adjusted GRM, compute adjustment when covariates are provided
        ADJUST_GRM_LDAK(
            grm_branched.needs_adjustment.map { row -> tuple(row[0], row[1], row[2], row[3], row[4]) },
            grm_branched.needs_adjustment.map { row -> tuple(row[6], row[7]) },
            quant_covariates,
            cat_covariates
        )

        pre_adjusted = grm_branched.adjusted.map { row ->
            tuple(row[6], row[0], row[1], row[2], row[3], row[4], row[5])
        }

        // Merge adjusted GRMs: pre-adjusted + newly adjusted
        grm_for_he = pre_adjusted.mix(ADJUST_GRM_LDAK.out.adjusted_grm)
    } else {
        grm_for_he = grm_branched.adjusted.map { row ->
            tuple(row[6], row[0], row[1], row[2], row[3], row[4], row[5])
        }.mix(
            grm_branched.needs_adjustment.map { row ->
                tuple(row[6], row[0], row[1], row[2], row[3], row[4], row[5])
            }
        )
    }

    // Get subset parameters (optional for batch error estimation)
    def subset_prefix = params.ldak_he_subset_prefix ?: ""
    def subset_number = params.ldak_he_subset_number ?: 0

    he_join = grm_for_he.join(PREPARE_PHENOCOV.out.phenotypes_noheader, by: 0)

    he_grm = he_join.map { _phenotype_name, grm_name, grm_bin, grm_id, grm_details, grm_adjust, grm_root, phenotypes_file ->
        tuple(grm_name, grm_bin, grm_id, grm_details, grm_adjust, grm_root)
    }

    he_pheno = he_join.map { phenotype_name, _grm_name, _grm_bin, _grm_id, _grm_details, _grm_adjust, _grm_root, phenotypes_file ->
        tuple(phenotype_name, phenotypes_file)
    }

    // Run HE regression
    LDAK_HE(
        he_grm,
        keep_file,
        he_pheno,
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
