/*
========================================================================================
    LDAK SumCors Genetic Correlation Workflow
========================================================================================
    Estimates genetic correlations between traits from GWAS summary statistics
    using pre-computed tagging files.

    Optional: Convert summary statistics to GRCh37 using MungeSumstats liftover.
    Also applies MAF filtering (default: 0.01) when liftover is enabled.
========================================================================================
*/

include { LIFTOVER_SUMSTATS as LIFTOVER_TRAIT1 } from '../../modules/local/ldak/liftover_sumstats'
include { LIFTOVER_SUMSTATS as LIFTOVER_TRAIT2 } from '../../modules/local/ldak/liftover_sumstats'
include { LDAK_SUMCORS                         } from '../../modules/local/ldak/ldak_sumcors'

workflow LDAK_SUMCORS_WORKFLOW {
    take:
    summary_stats_pairs_ch   // Channel: tuple(trait1_name, summary_stats1_file, trait2_name, summary_stats2_file)
    tagfile                  // Path: pre-computed tagging file

    main:
    // Determine if liftover is needed (LDAK tagfiles are typically GRCh37)
    def run_liftover = params.ldak_sumcors_liftover ?: false
    def target_build = params.ldak_sumcors_target_build ?: 'GRCh37'
    def source_build = params.ldak_sumcors_source_build ?: 'auto'
    def frq_filter = params.ldak_sumcors_frq_filter ?: 0.01

    if (run_liftover) {
        // Extract trait 1 summary stats with pair context
        trait1_ch = summary_stats_pairs_ch.map { trait1_name, stats1, trait2_name, stats2 ->
            tuple(trait1_name, stats1)
        }

        // Extract trait 2 summary stats with pair context
        trait2_ch = summary_stats_pairs_ch.map { trait1_name, stats1, trait2_name, stats2 ->
            tuple(trait2_name, stats2)
        }

        // Liftover both traits (using aliased process names to run in parallel)
        // Also applies MAF filtering
        LIFTOVER_TRAIT1(trait1_ch, target_build, source_build, frq_filter)
        LIFTOVER_TRAIT2(trait2_ch, target_build, source_build, frq_filter)

        // Reconstruct pairs by joining lifted results with original pair info
        // Create a channel with pair context (trait1_name, trait2_name) for joining
        pair_context_ch = summary_stats_pairs_ch.map { trait1_name, stats1, trait2_name, stats2 ->
            tuple(trait1_name, trait2_name)
        }

        // Join lifted trait1 results back
        lifted_trait1_ch = pair_context_ch
            .join(LIFTOVER_TRAIT1.out.lifted_sumstats, by: 0)  // Join by trait1_name
            // Result: tuple(trait1_name, trait2_name, lifted_stats1)

        // Join lifted trait2 results
        sumstats_pairs_for_analysis = lifted_trait1_ch
            .map { trait1_name, trait2_name, lifted_stats1 ->
                tuple(trait2_name, trait1_name, lifted_stats1)
            }
            .join(LIFTOVER_TRAIT2.out.lifted_sumstats, by: 0)  // Join by trait2_name
            .map { trait2_name, trait1_name, lifted_stats1, lifted_stats2 ->
                tuple(trait1_name, lifted_stats1, trait2_name, lifted_stats2)
            }
    } else {
        sumstats_pairs_for_analysis = summary_stats_pairs_ch
    }

    // Run LDAK SumCors for genetic correlation estimation
    LDAK_SUMCORS(
        sumstats_pairs_for_analysis,
        tagfile
    )

    emit:
    correlation_results = LDAK_SUMCORS.out.correlation_results
}
