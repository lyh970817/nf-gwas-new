process RUN_REML {
    tag "gcta_reml"
    publishDir "${params.pubDir}/gcta_greml", mode: 'copy', pattern: "*.hsq"

    input:
    tuple val(snp_group), val(prefix), path(grm_id), path(grm_bin), path(grm_n_bin)
    path phenotypes_file
    path qcovariates_file
    path covariates_file

    output:
    path "*.hsq", emit: reml_results

    script:
    def out = phenotypes_file.baseName
    def qcovar_param = qcovariates_file ? "--qcovar ${qcovariates_file}" : ''
    def covar_param = covariates_file ? "--covar ${covariates_file}" : ''

    """
    # Run GCTA REML analysis
    gcta \\
        --reml \\
        --grm ${prefix} \\
        --pheno ${phenotypes_file} \\
        ${qcovar_param} \\
        ${covar_param} \\
        --out ${out} \\
        --thread-num ${task.cpus}
    """
}
