/*
========================================================================================
    LDAK Adjust GRM Module
========================================================================================
    Purpose: Adjust kinship matrix for covariates
    - Required for HE and PCGC regression
    - Creates .grm.root file containing adjusted values
    - Enables "--he" and "--pcgc" to use adjusted kinships

    Documentation: LDAK manual section on --adjust-grm
========================================================================================
*/

process ADJUST_GRM_LDAK {
  tag "adjust_grm_${combined_grm_name}"
  publishDir "${params.pubDir}/ldak/adjusted_grm", mode: 'copy'

  input:
  tuple val(combined_grm_name), path(combined_grm_bin), path(combined_grm_id), path(combined_grm_details), path(combined_grm_adjust)
  path phenotype_file
  path quant_covariates_file
  path cat_covariates_file

  output:
  tuple val("${grm_basename}_adj"), path("${grm_basename}_adj.grm.bin"), path("${grm_basename}_adj.grm.id"), path("${grm_basename}_adj.grm.details"), path("${grm_basename}_adj.grm.adjust"), path("${grm_basename}_adj.grm.root"), emit: adjusted_grm

  script:
  // Handle optional covariate files: check if truthy (not empty list [])
  def quant_covar_param = quant_covariates_file ? "--covar ${quant_covariates_file}" : ''
  // Note: --adjust-grm does not support --factors, only --covar
  // Categorical covariates must be dummy-coded and included in quant covariates file
  // Extract basename from grm_id for output file naming (in case combined_grm_name is a full path)
  grm_basename = combined_grm_id.baseName.replace('.grm', '')

  """
    # Adjust kinship matrix for covariates
    # This creates a .grm.root file that HE and PCGC can use
    # NOTE: --adjust-grm only supports quantitative covariates
    # Note: grm_basename is extracted from combined_grm_id filename to handle full path values
    ldak6 --adjust-grm ${grm_basename}_adj \\
          --grm ${combined_grm_bin.baseName.replace('.grm', '')} \\
          --pheno ${phenotype_file} \\
          --mpheno 1 \\
          ${quant_covar_param} \\
          --max-threads ${task.cpus}
    """
}
