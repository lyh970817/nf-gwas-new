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
    phenotype_meta_ch // Channel: tuple(phenotype_name, phenotype_file, is_binary)
    covariates_file   // Path to covariates file (optional, can be [])

    main:
    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotype_meta_ch.map { phenotype_name, phenotypes_file, _is_binary -> tuple(phenotype_name, phenotypes_file) },
        covariates_file
    )

    // Get the covariates files (optional outputs from PREPARE_PHENOCOV)
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .toList()
        .map { files -> files ? files[0] : [] }
    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .toList()
        .map { files -> files ? files[0] : [] }

    phenotype_binary_flags = phenotype_meta_ch
        .map { phenotype_name, _phenotypes_file, is_binary -> tuple(phenotype_name, is_binary) }

    phenotypes_with_binary = PREPARE_PHENOCOV.out.phenotypes_noheader
        .join(phenotype_binary_flags, by: 0)
        .map { phenotype_name, phenotype_file, is_binary -> tuple(phenotype_name, phenotype_file, is_binary) }

    reml_pairs = grm.combine(phenotypes_with_binary)
    grm_for_reml = reml_pairs.map { grm_name, grm_bin, grm_id, grm_details, grm_adjust, _phenotype_name, _phenotype_file, _is_binary ->
        tuple(grm_name, grm_bin, grm_id, grm_details, grm_adjust)
    }
    pheno_for_reml = reml_pairs.map { _grm_name, _grm_bin, _grm_id, _grm_details, _grm_adjust, phenotype_name, phenotype_file, is_binary ->
        tuple(phenotype_name, phenotype_file, is_binary)
    }

    // Run LDAK REML analysis using pre-computed kinship
    // If grm is already filtered, keep_file should be [] (empty)
    LDAK_REML(
        grm_for_reml,
        keep_file,
        pheno_for_reml,
        quant_covariates,
        cat_covariates
    )

    emit:
    phenotypes_noheader = PREPARE_PHENOCOV.out.phenotypes_noheader
    covariates_quant_noheader = PREPARE_PHENOCOV.out.covariates_quant_noheader
    covariates_cat_noheader = PREPARE_PHENOCOV.out.covariates_cat_noheader
    reml_results = LDAK_REML.out.reml_results
}
