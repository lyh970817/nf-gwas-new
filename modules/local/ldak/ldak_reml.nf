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
    path "reml_ldak*", emit: reml_results

    script:
    def quant_covar_param = quant_covariates_file ? "--covar ${quant_covariates_file}" : ''
    def cat_covar_param = cat_covariates_file ? "--factors ${cat_covariates_file}" : ''

    """
    # Run LDAK REML analysis
    ldak6 --reml reml_ldak --pheno ${phenotype_file} --keep ${filtered_keep} --grm ${combined_grm_name} ${quant_covar_param} ${cat_covar_param} --max-threads ${task.cpus}
    """
}
