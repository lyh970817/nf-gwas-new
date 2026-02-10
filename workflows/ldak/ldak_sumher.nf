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
    summary_stats_ch   // Channel: tuple(trait_name, summary_stats_file, prevalence_override, ascertainment_override)
    tagfile            // Path: pre-computed tagging file

    main:
    // Determine if liftover is needed (LDAK tagfiles are typically GRCh37)
    def run_liftover = params.ldak_sumstats_liftover ?: false
    def target_build = params.ldak_sumstats_target_build ?: 'GRCh37'
    def source_build = params.ldak_sumstats_source_build ?: 'auto'
    def frq_filter = params.ldak_sumstats_frq_filter ?: 0.01

    if (run_liftover) {
        liftover_input_ch = summary_stats_ch.map { trait_name, summary_stats_file, _prevalence_override, _ascertainment_override ->
            tuple(trait_name, summary_stats_file)
        }

        prevalence_ascertainment_ch = summary_stats_ch.map { trait_name, _summary_stats_file, prevalence_override, ascertainment_override ->
            tuple(trait_name, prevalence_override, ascertainment_override)
        }

        // Convert summary statistics to target build (typically GRCh37 for LDAK)
        // Also applies MAF filtering
        LIFTOVER_SUMSTATS(
            liftover_input_ch,
            target_build,
            source_build,
            frq_filter
        )

        sumstats_for_analysis = LIFTOVER_SUMSTATS.out.lifted_sumstats
            .join(prevalence_ascertainment_ch, by: 0)
            .map { trait_name, lifted_sumstats, prevalence_override, ascertainment_override ->
                tuple(trait_name, lifted_sumstats, prevalence_override, ascertainment_override)
            }
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
