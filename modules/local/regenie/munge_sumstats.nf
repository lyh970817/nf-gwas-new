process MUNGE_SUMSTATS {

    tag "${phenotype}"

    publishDir "${params.pubDir}/regenie/munged", mode: 'copy', pattern: '*.tsv.gz'
    publishDir "${params.pubDir}/logs", mode: 'copy', pattern: '*.log'

    label 'process_medium'

    input:
    tuple val(phenotype), path(sumstats_file)
    val genome_build

    output:
    tuple val(phenotype), path("${phenotype}_munged.tsv.gz"), emit: munged_sumstats
    path "*.log", emit: log, optional: true

    script:
    // Use explicit null check since 0 is a valid value (means disabled)
    def dbsnp = params.munge_dbsnp_version != null ? params.munge_dbsnp_version : 0
    """
    munge_sumstats.R \\
        ${sumstats_file} \\
        ${phenotype}_munged.tsv.gz \\
        ${genome_build} \\
        ${dbsnp} \\
        2>&1 | tee ${phenotype}_munge.log
    """
}
