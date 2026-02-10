nextflow.enable.dsl = 2

include { SYNC_SUMSTATS_LINKS } from '../../../modules/local/sumstats/sync_sumstats_links'
include { LDSC_H2_WORKFLOW } from '../../../workflows/ldsc/ldsc_h2'

workflow SUMSTATS_SYNC_TO_LDSC {
    take:
    generated_sumstats_ch   // tuple(trait_name, method_name, sumstats_file)
    summary_stats_dir       // val

    main:
    SYNC_SUMSTATS_LINKS(generated_sumstats_ch, summary_stats_dir)

    existing_summary_stats_ch = Channel.fromPath("${summary_stats_dir}/*", checkIfExists: false)
        .filter { it.isFile() }
        .map { stats_file ->
            def trait_name = stats_file.baseName.replaceAll(/\..*/, '')
            tuple(trait_name, stats_file)
        }

    all_summary_stats_ch = existing_summary_stats_ch.mix(SYNC_SUMSTATS_LINKS.out.linked_sumstats)

    LDSC_H2_WORKFLOW(all_summary_stats_ch)

    emit:
    linked_sumstats = SYNC_SUMSTATS_LINKS.out.linked_sumstats
    h2_results = LDSC_H2_WORKFLOW.out.heritability_results
}
