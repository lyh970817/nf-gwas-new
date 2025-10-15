process LDAK_SUMHER {
    tag "ldak_sumher_${trait_name}"
    publishDir "${params.pubDir}/ldak/sumher", mode: 'copy'
    label 'process_low'

    input:
    tuple val(trait_name), path(summary_stats)
    path tagfile

    output:
    path "${trait_name}.hers", emit: heritability_results
    path "${trait_name}.enrich", emit: enrichment_results, optional: true
    path "${trait_name}.load", optional: true
    path "${trait_name}.progress", optional: true

    script:
    def check_sums = params.ldak_sumher_check_sums ? "" : "--check-sums NO"
    def prevalence = params.ldak_sumher_prevalence ? "--prevalence ${params.ldak_sumher_prevalence}" : ""
    def cutoff = params.ldak_sumher_cutoff ? "--cutoff ${params.ldak_sumher_cutoff}" : ""

    """
    # Run LDAK SumHer for heritability estimation
    ldak6 --sum-hers ${trait_name} \\
        --summary ${summary_stats} \\
        --tagfile ${tagfile} \\
        ${check_sums} \\
        ${prevalence} \\
        ${cutoff} \\
        --max-threads ${task.cpus}
    """
}
