process LDAK_HE {
    tag "ldak_he_${grm_name}"
    publishDir "${params.pubDir}/ldak/he", mode: 'copy'

    input:
    // GRM tuple; grm_root is [] for unadjusted GRMs
    // Should already contain only unrelated individuals if derived from filtered_grm
    tuple val(grm_name), path(grm_bin), path(grm_id), path(grm_details), path(grm_adjust), path(grm_root)
    path keep_file  // Optional: .keep file for sample filtering (use [] if GRM is already filtered)
    tuple val(phenotype_name), path(phenotype_file)
    path quant_covariates_file
    path cat_covariates_file
    val subset_prefix
    val subset_number

    output:
    tuple val(phenotype_name), path("he_*.*"), emit: he_results

    script:
    // Handle optional files: check if truthy (not empty list [])
    def quant_covar_param = quant_covariates_file ? "--covar ${quant_covariates_file}" : ''
    def cat_covar_param = cat_covariates_file ? "--factors ${cat_covariates_file}" : ''
    def keep_param = keep_file ? "--keep ${keep_file}" : ''
    def subset_prefix_param = subset_prefix ? "--subset-prefix ${subset_prefix}" : ''
    def subset_number_param = subset_number ? "--subset-number ${subset_number}" : ''
    // Extract basename from grm_id for output file naming (in case grm_name is a full path)
    def grm_basename = grm_id.baseName.replace('.grm', '')
    def phenotype_slug = phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')

    """
    # Run LDAK HE analysis with adjusted GRM
    # If GRM is already filtered (unrelated individuals only), no --keep is needed
    # Note: grm_basename is extracted from grm_id filename to handle full path grm_name values
    ldak6 --he he_${phenotype_slug}_${grm_basename} \\
        --pheno ${phenotype_file} \\
        --mpheno 1 \\
        --grm ${grm_bin.baseName.replace('.grm', '')} \\
        ${keep_param} \\
        ${quant_covar_param} \\
        ${cat_covar_param} \\
        ${subset_prefix_param} \\
        ${subset_number_param} \\
        --max-threads ${task.cpus}
    """
}
