process LDAK_SUMCORS {
    tag "ldak_sumcors_${trait1_name}_${trait2_name}"
    publishDir "${params.pubDir}/ldak/sumcors", mode: 'copy'
    label 'process_low'

    input:
    tuple val(trait1_name), path(summary_stats1), val(trait2_name), path(summary_stats2)
    path tagfile

    output:
    path "${trait1_name}.${trait2_name}.cors", emit: correlation_results
    path "${trait1_name}.${trait2_name}.load", optional: true
    path "${trait1_name}.${trait2_name}.progress", optional: true

    script:
    def check_sums = params.ldak_sumcors_check_sums ? "" : "--check-sums NO"
    def prevalence1 = params.ldak_sumcors_prevalence1 ? "--prevalence ${params.ldak_sumcors_prevalence1}" : ""
    def prevalence2 = params.ldak_sumcors_prevalence2 ? "--prevalence2 ${params.ldak_sumcors_prevalence2}" : ""

    """
    # Run LDAK Sumcors for genetic correlation estimation
    ldak6 --sum-cors ${trait1_name}.${trait2_name} \\
        --summary ${summary_stats1} \\
        --summary2 ${summary_stats2} \\
        --tagfile ${tagfile} \\
        ${check_sums} \\
        ${prevalence1} \\
        ${prevalence2} \\
        --max-threads ${task.cpus}
    """
}
