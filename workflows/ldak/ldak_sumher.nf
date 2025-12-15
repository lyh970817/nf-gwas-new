/*
========================================================================================
    LDAK SumHer Heritability Workflow
========================================================================================
    Estimates SNP heritability and heritability enrichments from GWAS summary statistics
    using pre-computed tagging files.

    Optional: Convert summary statistics to GRCh37 using MungeSumstats liftover.
    Also applies MAF filtering (default: 0.01) when liftover is enabled.
========================================================================================
*/

include { LIFTOVER_SUMSTATS } from '../../modules/local/ldak/liftover_sumstats'
include { LDAK_SUMHER       } from '../../modules/local/ldak/ldak_sumher'

workflow LDAK_SUMHER_WORKFLOW {
    take:
    summary_stats_ch   // Channel: tuple(trait_name, summary_stats_file)
    tagfile            // Path: pre-computed tagging file

    main:
    // Determine if liftover is needed (LDAK tagfiles are typically GRCh37)
    def run_liftover = params.ldak_sumher_liftover ?: false
    def target_build = params.ldak_sumher_target_build ?: 'GRCh37'
    def source_build = params.ldak_sumher_source_build ?: 'auto'
    def frq_filter = params.ldak_sumher_frq_filter ?: 0.01

    if (run_liftover) {
        // Convert summary statistics to target build (typically GRCh37 for LDAK)
        // Also applies MAF filtering
        LIFTOVER_SUMSTATS(
            summary_stats_ch,
            target_build,
            source_build,
            frq_filter
        )
        sumstats_for_analysis = LIFTOVER_SUMSTATS.out.lifted_sumstats
    } else {
        sumstats_for_analysis = summary_stats_ch
    }

    // Run LDAK SumHer for heritability estimation
    LDAK_SUMHER(
        sumstats_for_analysis,
        tagfile
    )

    emit:
    heritability_results = LDAK_SUMHER.out.heritability_results
    enrichment_results = LDAK_SUMHER.out.enrichment_results
}
