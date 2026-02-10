process LDAK_REML {
    tag "ldak_reml_${grm_name}"
    publishDir "${params.pubDir}/ldak/reml", mode: 'copy'

    input:
    // Accepts either filtered_grm (unrelated individuals only) or combined_grm
    // If using filtered_grm, no --keep parameter is needed
    // If using combined_grm with optional keep_file, --keep will be added
    tuple val(grm_name), path(grm_bin), path(grm_id), path(grm_details), path(grm_adjust)
    path keep_file  // Optional: .keep file for sample filtering (use [] if GRM is already filtered)
    tuple val(phenotype_name), path(phenotype_file), val(is_binary)
    path quant_covariates_file
    path cat_covariates_file

    output:
    path "reml_*.coeff", optional: true
    path "reml_*.combined", optional: true
    path "reml_*.cross", optional: true
    path "reml_*.indi.blp", optional: true
    path "reml_*.indi.res", optional: true
    path "reml_*.progress", optional: true
    tuple val(phenotype_name), path("reml_*.reml"), emit: reml_results
    path "reml_*.share", optional: true
    path "reml_*.vars", optional: true

    script:
    // Handle optional files: check if truthy (not empty list [])
    def quant_covar_param = quant_covariates_file ? "--covar ${quant_covariates_file}" : ''
    def cat_covar_param = cat_covariates_file ? "--factors ${cat_covariates_file}" : ''
    def keep_param = keep_file ? "--keep ${keep_file}" : ''
    def prevalence_param = (is_binary && params.ldak_reml_prevalence != null) ? "--prevalence ${params.ldak_reml_prevalence}" : ''
    // Extract basename from grm_name for output file naming (in case grm_name is a full path)
    def grm_basename = grm_id.baseName.replace('.grm', '')
    def phenotype_slug = phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')

    """
    # Run LDAK REML analysis
    # If GRM is already filtered (unrelated individuals only), no --keep is needed
    # If using combined GRM with keep_file, --keep filters to unrelated individuals
    # Note: grm_basename is extracted from grm_id filename to handle full path grm_name values
    # For binary traits, include --prevalence if params.ldak_reml_prevalence is provided
    ldak6 --reml reml_${phenotype_slug}_${grm_basename} \\
        --pheno ${phenotype_file} \\
        --mpheno 1 \\
        --grm ${grm_bin.baseName.replace('.grm', '')} \\
        ${keep_param} \\
        ${quant_covar_param} \\
        ${cat_covar_param} \\
        ${prevalence_param} \\
        --max-threads ${task.cpus}
    """
}
