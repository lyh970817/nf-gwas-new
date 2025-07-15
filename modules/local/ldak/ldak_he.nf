process LDAK_HE {
    tag "ldak_he"
    publishDir "${params.pubDir}/ldak/he", mode: 'copy'

    input:
    tuple val(combined_grm_name), path(combined_grm_bin), path(combined_grm_id), path(combined_grm_details), path(combined_grm_adjust)
    tuple val(filtered_list_name), path(filtered_keep), path(filtered_lose), path(filtered_maxrel)
    path phenotype_file
    path quant_covariates_file
    path cat_covariates_file
    val subset_prefix
    val subset_number

    output:
    path "he_${combined_grm_name}.coeff"
    path "he_${combined_grm_name}.combined"
    path "he_${combined_grm_name}.cross"
    path "he_${combined_grm_name}.indi.blp"
    path "he_${combined_grm_name}.indi.res"
    path "he_${combined_grm_name}.progress"
    path "he_${combined_grm_name}.reml", emit: he_results
    path "he_${combined_grm_name}.share"
    path "he_${combined_grm_name}.vars"

    script:
    def quant_covar_param = quant_covariates_file ? "--covar ${quant_covariates_file}" : ''
    def cat_covar_param = cat_covariates_file ? "--factors ${cat_covariates_file}" : ''
    def keep_param = filtered_keep ? "--keep ${filtered_keep}" : ''
    def subset_prefix_param = subset_prefix ? "--subset-prefix ${subset_prefix}" : ''
    def subset_number_param = subset_number ? "--subset-number ${subset_number}" : ''

    """
    # Run LDAK HE analysis
    ldak6 --he he_${combined_grm_name} --pheno ${phenotype_file} ${keep_param} --grm ${combined_grm_name} ${quant_covar_param} ${cat_covar_param} ${subset_prefix_param} ${subset_number_param} --max-threads ${task.cpus}
    """
}
