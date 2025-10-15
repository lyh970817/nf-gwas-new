/*
========================================================================================
    LDAK SumHer Heritability Workflow
========================================================================================
    Estimates SNP heritability and heritability enrichments from GWAS summary statistics
    using pre-computed tagging files.
========================================================================================
*/

include { LDAK_SUMHER } from '../../modules/local/ldak/ldak_sumher'

workflow LDAK_SUMHER_WORKFLOW {
    take:
    summary_stats_ch   // Channel: tuple(trait_name, summary_stats_file)
    tagfile            // Path: pre-computed tagging file

    main:
    // Run LDAK SumHer for heritability estimation
    LDAK_SUMHER(
        summary_stats_ch,
        tagfile
    )

    emit:
    heritability_results = LDAK_SUMHER.out.heritability_results
    enrichment_results = LDAK_SUMHER.out.enrichment_results
}
