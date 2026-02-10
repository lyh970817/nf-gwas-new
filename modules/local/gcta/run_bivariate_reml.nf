process RUN_BIVARIATE_REML {
    tag "bivariate_reml_${prefix}"
    publishDir "${params.pubDir}/gcta_bivariate_greml", mode: 'copy', pattern: "*.hsq"
    publishDir "${params.pubDir}/gcta_bivariate_greml", mode: 'copy', pattern: "*.log"

    input:
    tuple val(snp_group), val(prefix), path(grm_id), path(grm_bin), path(grm_n_bin)
    tuple val(pair_name), path(phenotypes_file)
    path qcovariates_file
    path covariates_file

    output:
    path "*.hsq", emit: bivariate_results
    path "*.log", emit: log_file

    script:
    def pair_slug = pair_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')
    def out = pair_slug
    def qcovar_param = qcovariates_file ? "--qcovar ${qcovariates_file}" : ''
    def covar_param = covariates_file ? "--covar ${covariates_file}" : ''

    """
    # Run GCTA bivariate REML analysis for genetic correlation estimation
    # --reml-bivar 1 2: bivariate REML mode with phenotype columns 1 and 2
    gcta \\
        --reml-bivar 1 2 \\
        --grm ${prefix} \\
        --pheno ${phenotypes_file} \\
        ${qcovar_param} \\
        ${covar_param} \\
        --out ${out} \\
        --thread-num ${task.cpus}
    """
}
