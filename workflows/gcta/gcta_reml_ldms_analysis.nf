/*
========================================================================================
    GCTA REML-LDMS Analysis Workflow - Partitioned Heritability with Pre-computed GRMs
========================================================================================

    Purpose: Run REML-LDMS heritability analysis using pre-computed multi-GRM files

    This workflow is designed to be used when:
    1. Multiple GRMs (stratified by LD) have already been computed
    2. You want to run partitioned heritability with the same GRMs on different phenotypes
    3. You need to separate GRM computation from analysis for workflow flexibility

    Pipeline:
    1. PREPARE_PHENOCOV: Format phenotype/covariate files (remove headers, split covariates)
    2. RUN_REML_LDMS: Run GCTA multi-component REML heritability estimation

    Input Format:
    - mgrm_file: Multi-GRM file listing all GRM prefixes
    - all_grm_files: Collected GRM files (grm.id, grm.bin, grm.N.bin for each SNP group)
========================================================================================
*/

include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { RUN_REML_LDMS } from '../../modules/local/gcta/run_reml_ldms'

workflow GCTA_REML_LDMS_ANALYSIS {
    take:
    mgrm_file           // Multi-GRM file listing all GRM prefixes
    all_grm_files       // Collected GRM files (all grm.id, grm.bin, grm.N.bin files)
    phenotype_meta_ch   // Channel: tuple(phenotype_name, phenotype_file, is_binary)
    covariates_file     // Path to covariates file (optional, can be [])

    main:
    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotype_meta_ch.map { phenotype_name, phenotypes_file, _is_binary -> tuple(phenotype_name, phenotypes_file) },
        covariates_file,
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .collect()
        .map { files -> files ? files[0] : [] }
    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .collect()
        .map { files -> files ? files[0] : [] }

    def mgrm_value = mgrm_file.collect().map { files -> files ? files[0] : [] }
    def all_grm_files_value = all_grm_files.collect().map { files -> files.flatten() }

    // Run REML-LDMS analysis using the pre-computed multi-GRM files
    RUN_REML_LDMS(
        mgrm_value,
        all_grm_files_value,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates,
    )

    emit:
    phenotypes_noheader = PREPARE_PHENOCOV.out.phenotypes_noheader
    covariates_quant_noheader = PREPARE_PHENOCOV.out.covariates_quant_noheader
    covariates_cat_noheader = PREPARE_PHENOCOV.out.covariates_cat_noheader
    reml_results = RUN_REML_LDMS.out.reml_results
}
