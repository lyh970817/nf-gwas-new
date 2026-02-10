/*
========================================================================================
    LDSC Genetic Correlation Workflow
========================================================================================
    Estimates pairwise genetic correlations from summary statistics using LDSC.
========================================================================================
*/

include { LDSC_MUNGE_SUMSTATS } from '../../modules/local/ldsc/munge_sumstats'
include { LDSC_RG             } from '../../modules/local/ldsc/ldsc_rg'

workflow LDSC_RG_WORKFLOW {
    take:
    summary_stats_pairs_ch   // Channel: tuple(trait1_name, summary_stats1_file, trait2_name, summary_stats2_file)

    main:
    if (!params.ldsc_ref_ld_chr) {
        error("LDSC genetic correlation requires --ldsc_ref_ld_chr")
    }
    if (!params.ldsc_w_ld_chr) {
        error("LDSC genetic correlation requires --ldsc_w_ld_chr")
    }

    trait1_ch = summary_stats_pairs_ch.map { trait1_name, summary_stats1, trait2_name, summary_stats2 ->
        tuple(trait1_name, summary_stats1)
    }
    trait2_ch = summary_stats_pairs_ch.map { trait1_name, summary_stats1, trait2_name, summary_stats2 ->
        tuple(trait2_name, summary_stats2)
    }

    all_traits_ch = trait1_ch.concat(trait2_ch)
        .toSortedList { a, b -> a[0] <=> b[0] }
        .flatMap { rows ->
            def deduped = []
            def seen = [] as Set
            rows.each { row ->
                if (!seen.contains(row[0])) {
                    seen << row[0]
                    deduped << row
                }
            }
            return deduped
        }

    LDSC_MUNGE_SUMSTATS(all_traits_ch)

    munged_trait1_ch = summary_stats_pairs_ch
        .map { trait1_name, summary_stats1, trait2_name, summary_stats2 ->
            tuple(trait1_name, trait2_name)
        }
        .combine(LDSC_MUNGE_SUMSTATS.out.munged_sumstats, by: 0)

    munged_pairs_ch = munged_trait1_ch
        .map { trait1_name, trait2_name, munged_sumstats1 ->
            tuple(trait2_name, trait1_name, munged_sumstats1)
        }
        .combine(LDSC_MUNGE_SUMSTATS.out.munged_sumstats, by: 0)
        .map { trait2_name, trait1_name, munged_sumstats1, munged_sumstats2 ->
            tuple(trait1_name, munged_sumstats1, trait2_name, munged_sumstats2)
        }

    LDSC_RG(
        munged_pairs_ch,
        params.ldsc_ref_ld_chr,
        params.ldsc_w_ld_chr
    )

    emit:
    correlation_results = LDSC_RG.out.correlation_results
    munge_logs = LDSC_MUNGE_SUMSTATS.out.munge_log
}
