/*
========================================================================================
    LDAK SumCors Genetic Correlation Workflow
========================================================================================
    Estimates genetic correlations between traits from GWAS summary statistics
    using pre-computed tagging files.
========================================================================================
*/

include { LDAK_SUMCORS } from '../../modules/local/ldak/ldak_sumcors'

workflow LDAK_SUMCORS_WORKFLOW {
    take:
    summary_stats_pairs_ch   // Channel: tuple(trait1_name, summary_stats1_file, trait2_name, summary_stats2_file)
    tagfile                  // Path: pre-computed tagging file

    main:
    // Run LDAK SumCors for genetic correlation estimation
    LDAK_SUMCORS(
        summary_stats_pairs_ch,
        tagfile
    )

    emit:
    correlation_results = LDAK_SUMCORS.out.correlation_results
}
