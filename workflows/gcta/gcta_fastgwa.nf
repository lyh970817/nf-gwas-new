/*
========================================================================================
    GCTA FastGWA Workflow - Fast Association Testing with GRM
========================================================================================

    Purpose: Run complete FastGWA-MLM association testing including GRM computation

    This workflow computes the GRM, creates a sparse version for efficiency,
    and runs FastGWA-MLM association testing. FastGWA is orders of magnitude
    faster than standard GWAS for large samples (>50k).

    Pipeline:
    1. GCTA_GRM: Compute genetic relationship matrix (with sparse output)
    2. GCTA_FASTGWA_ANALYSIS: Run FastGWA-MLM association testing

    For workflows that need to reuse GRMs, use GCTA_GRM (with create_sparse_grm=true)
    and GCTA_FASTGWA_ANALYSIS separately.
========================================================================================
*/

include { GCTA_GRM } from './gcta_grm'
include { GCTA_FASTGWA_ANALYSIS } from './gcta_fastgwa_analysis'

workflow GCTA_FASTGWA {
    take:
    imputed_plink2_ch   // Channel with imputed PLINK2 files for GRM and association
    phenotypes_file     // Path to phenotypes file
    covariates_file     // Path to covariates file (optional)
    nparts_gcta         // Number of parts for GCTA GRM calculation
    sparse_cutoff       // Cutoff for sparse GRM (default: 0.05)

    main:
    // Create a default channel for snps_to_extract (single group "0")
    def snps_to_extract_ch = Channel.of(["0", []])

    // Run GCTA GRM workflow with sparse GRM creation enabled
    GCTA_GRM(
        imputed_plink2_ch,
        nparts_gcta,
        snps_to_extract_ch,
        true,           // create_sparse_grm
        sparse_cutoff,  // sparse_cutoff
        false           // skip_relatedness_filter
    )

    // Run FastGWA-MLM analysis using the sparse GRM
    GCTA_FASTGWA_ANALYSIS(
        imputed_plink2_ch,
        GCTA_GRM.out.sparse_grm_files,
        phenotypes_file,
        covariates_file,
    )

    emit:
    // Dense GRM files (for potential reuse)
    grm_files = GCTA_GRM.out.grm_files
    // Sparse GRM files
    sparse_grm_files = GCTA_GRM.out.sparse_grm_files
    // FastGWA association results
    fastgwa_results = GCTA_FASTGWA_ANALYSIS.out.fastgwa_results
}
