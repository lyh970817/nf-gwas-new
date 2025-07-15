process LDAK_REML {
    tag "ldak_reml"
    publishDir "${params.pubDir}/ldak/reml", mode: 'copy'

    input:
    tuple val(combined_grm_name), path(combined_grm_bin), path(combined_grm_id), path(combined_grm_details), path(combined_grm_adjust)
    tuple val(filtered_list_name), path(filtered_keep), path(filtered_lose), path(filtered_maxrel)
    path phenotype_file
    path quant_covariates_file
    path cat_covariates_file

    output:
    path "reml_${combined_grm_name}.coeff"
    path "reml_${combined_grm_name}.combined"
    path "reml_${combined_grm_name}.cross"
    path "reml_${combined_grm_name}.indi.blp"
    path "reml_${combined_grm_name}.indi.res"
    path "reml_${combined_grm_name}.progress"
    path "reml_${combined_grm_name}.reml", emit: reml_results
    path "reml_${combined_grm_name}.share"
    path "reml_${combined_grm_name}.vars"

    script:
    def quant_covar_param = quant_covariates_file ? "--covar ${quant_covariates_file}" : ''
    def cat_covar_param = cat_covariates_file ? "--factors ${cat_covariates_file}" : ''
    def keep_param = filtered_keep ? "--keep ${filtered_keep}" : ''

    """
    # Run LDAK REML analysis
    ldak6 --reml reml_${combined_grm_name} --pheno ${phenotype_file} ${keep_param} --grm ${combined_grm_name} ${quant_covar_param} ${cat_covar_param} --max-threads ${task.cpus}
    """
}
