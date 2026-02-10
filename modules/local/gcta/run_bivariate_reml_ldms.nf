process RUN_BIVARIATE_REML_LDMS {
    tag "bivariate_reml_ldms"
    publishDir "${params.pubDir}/gcta_bivariate_greml_ldms", mode: 'copy', pattern: "*.hsq"
    publishDir "${params.pubDir}/gcta_bivariate_greml_ldms", mode: 'copy', pattern: "*.log"

    input:
    path mgrm_file
    path grm_files
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
    # Run GCTA bivariate REML-LDMS analysis with multiple GRMs
    # --reml-bivar 1 2: bivariate REML mode with phenotype columns 1 and 2
    # --mgrm: use multiple GRMs (LD-stratified)
    # --reml-bivar-no-constrain: allow estimates outside bounds (recommended for multi-GRM)
    # --reml-maxit: increase max iterations for convergence (multi-GRM requires more)
    gcta \\
        --reml-bivar 1 2 \\
        --mgrm ${mgrm_file} \\
        --pheno ${phenotypes_file} \\
        ${qcovar_param} \\
        ${covar_param} \\
        --reml-bivar-no-constrain \\
        --reml-maxit 500 \\
        --out ${out} \\
        --thread-num ${task.cpus}
    """
}
