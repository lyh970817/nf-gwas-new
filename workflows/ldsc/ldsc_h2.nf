/*
========================================================================================
    LDSC Heritability Workflow
========================================================================================
    Estimates SNP heritability from summary statistics using LDSC.
========================================================================================
*/

include { LDSC_MUNGE_SUMSTATS } from '../../modules/local/ldsc/munge_sumstats'
include { LDSC_H2             } from '../../modules/local/ldsc/ldsc_h2'

workflow LDSC_H2_WORKFLOW {
    take:
    summary_stats_ch   // Channel: tuple(trait_name, summary_stats_file)

    main:
    if (!params.ldsc_ref_ld_chr) {
        error("LDSC heritability requires --ldsc_ref_ld_chr")
    }
    if (!params.ldsc_w_ld_chr) {
        error("LDSC heritability requires --ldsc_w_ld_chr")
    }

    LDSC_MUNGE_SUMSTATS(summary_stats_ch)

    LDSC_H2(
        LDSC_MUNGE_SUMSTATS.out.munged_sumstats,
        params.ldsc_ref_ld_chr,
        params.ldsc_w_ld_chr
    )

    emit:
    heritability_results = LDSC_H2.out.heritability_results
    munge_logs = LDSC_MUNGE_SUMSTATS.out.munge_log
}
