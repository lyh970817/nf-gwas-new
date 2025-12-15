/*
========================================================================================
    LDAK REML Analysis Workflow - Heritability with Pre-computed Kinship
========================================================================================

    Purpose: Run LDAK REML heritability analysis using pre-computed kinship matrix

    This workflow is designed to be used when:
    1. Kinship has already been computed in a previous run
    2. You want to run heritability on the same kinship with different phenotypes
    3. You need to separate kinship computation from analysis for workflow flexibility

    Pipeline:
    1. PREPARE_PHENOCOV: Format phenotype/covariate files (remove headers, split covariates)
    2. LDAK_REML: Run REML heritability estimation

    Input Format:
    - grm: LDAK kinship files [prefix, bin, id, details, adjust]
           Can be either filtered_grm (already contains only unrelated individuals)
           or combined_grm with optional keep_file for filtering
    - keep_file: Optional .keep file (use [] if GRM is already filtered)
========================================================================================
*/

include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { LDAK_REML } from '../../modules/local/ldak/ldak_reml'

workflow LDAK_REML_ANALYSIS {
    take:
    grm               // Pre-computed kinship: tuple [prefix, bin, id, details, adjust]
    keep_file         // Optional .keep file for filtering (use [] if GRM is already filtered)
    phenotypes_file   // Path to phenotypes file
    covariates_file   // Path to covariates file (optional, can be [])

    main:
    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotypes_file,
        covariates_file
    )

    // Get the covariates files (optional outputs from PREPARE_PHENOCOV)
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader.ifEmpty([])
    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader.ifEmpty([])

    // Run LDAK REML analysis using pre-computed kinship
    // If grm is already filtered, keep_file should be [] (empty)
    LDAK_REML(
        grm,
        keep_file,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates
    )

    emit:
    phenotypes_noheader = PREPARE_PHENOCOV.out.phenotypes_noheader
    covariates_quant_noheader = PREPARE_PHENOCOV.out.covariates_quant_noheader
    covariates_cat_noheader = PREPARE_PHENOCOV.out.covariates_cat_noheader
    reml_results = LDAK_REML.out.reml_results
}
