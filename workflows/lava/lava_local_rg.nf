/*
========================================================================================
    LAVA Local Genetic Correlation Workflow
========================================================================================
    Estimates local genetic correlations between phenotypes using LAVA
    (Local Analysis of [co]Variant Association).

    This workflow runs:
    1. Univariate tests: Local heritability (h²) at each locus for each phenotype
    2. Bivariate tests: Local genetic correlation (rg) between phenotype pairs
       (filtered by univariate significance threshold)

    Reference: Werme et al. (2022) Nature Genetics. https://doi.org/10.1038/s41588-022-01017-y
========================================================================================
*/

include { LAVA_RUN_ANALYSIS } from '../../modules/local/lava/lava_run_analysis'

workflow LAVA_LOCAL_RG {
    take:
    analysis_id         // String: Unique analysis identifier
    ref_plink_ch        // Channel: tuple(bed, bim, fam) - PLINK reference files
    sumstats_ch         // Channel: list of summary statistics files
    loci_file           // Path: Locus definition file (LOC, CHR, START, STOP)
    sample_overlap_file // Path: Sample overlap file (optional, pass [] if not available)
    phenotype_info      // String: JSON array with phenotype metadata
    univ_threshold      // Float: P-value threshold for univariate filtering (default: 0.05)

    main:
    // Run LAVA analysis
    LAVA_RUN_ANALYSIS(
        analysis_id,
        ref_plink_ch.map { it[0] },  // bed
        ref_plink_ch.map { it[1] },  // bim
        ref_plink_ch.map { it[2] },  // fam
        sumstats_ch,
        loci_file,
        sample_overlap_file,
        phenotype_info,
        univ_threshold
    )

    emit:
    univ_results  = LAVA_RUN_ANALYSIS.out.univ_results
    bivar_results = LAVA_RUN_ANALYSIS.out.bivar_results
    log_file      = LAVA_RUN_ANALYSIS.out.log_file
}
