process RUN_REML_LDMS {
  tag "gcta_reml_ldms"
  publishDir "${params.pubDir}/gcta_greml_ldms", mode: 'copy', pattern: "*.hsq"

  input:
  path mgrm_file
  path grm_files
  tuple val(phenotype_name), path(phenotypes_file)
  path qcovariates_file
  path covariates_file

  output:
  path "*.hsq", emit: reml_results

  script:
  def phenotype_slug = phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')
  def out = phenotype_slug
  def qcovar_param = qcovariates_file ? "--qcovar ${qcovariates_file}" : ''
  def covar_param = covariates_file ? "--covar ${covariates_file}" : ''

  """
    # Run GCTA REML-LDMS analysis with multiple GRMs
    # --reml-no-constrain is temporary for testing
    gcta \\
        --reml-no-constrain \\
        --mgrm ${mgrm_file} \\
        --pheno ${phenotypes_file} \\
        ${qcovar_param} \\
        ${covar_param} \\
        --out ${out} \\
        --thread-num ${task.cpus}
    """
}
