/*
========================================================================================
    Liftover Summary Statistics Process
========================================================================================
    Converts GWAS summary statistics between genome builds (GRCh37 <-> GRCh38)
    using MungeSumstats::liftover() from Bioconductor.

    Also applies MAF filtering (default: 0.01) to remove rare variants.
========================================================================================
*/

process LIFTOVER_SUMSTATS {
    tag "liftover_${trait_name}"
    publishDir "${params.pubDir}/ldak/liftover", mode: 'copy', pattern: '*_lifted.tsv.gz'
    publishDir "${params.pubDir}/logs", mode: 'copy', pattern: '*.log'

    label 'process_low'

    input:
    tuple val(trait_name), path(summary_stats)
    val target_build      // Target genome build: "GRCh37" or "GRCh38"
    val source_build      // Source genome build: "GRCh37", "GRCh38", or "auto"
    val frq_filter        // MAF filter threshold (e.g., 0.01)

    output:
    tuple val(trait_name), path("${trait_name}_lifted.tsv.gz"), emit: lifted_sumstats
    path "${trait_name}_liftover.log", emit: log

    script:
    """
    liftover_sumstats.R \\
        ${summary_stats} \\
        ${trait_name}_lifted.tsv.gz \\
        ${target_build} \\
        ${source_build} \\
        ${frq_filter} \\
        2>&1 | tee ${trait_name}_liftover.log
    """
}
