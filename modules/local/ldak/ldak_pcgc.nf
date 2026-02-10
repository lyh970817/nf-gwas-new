/*
========================================================================================
    LDAK PCGC Regression Module
========================================================================================

    Purpose: Binary trait heritability estimation on liability scale
    - Critical for case-control studies
    - Converts observed-scale heritability to liability-scale
    - Requires disease prevalence parameter
    - Similar interface to LDAK_REML but with --pcgc flag

    Documentation: docs/external/ldak/06_pcgc-regression.md
========================================================================================
*/

process LDAK_PCGC {
    tag "ldak_pcgc_${grm_name}"
    publishDir "${params.pubDir}/ldak/pcgc", mode: 'copy'

    input:
    // GRM tuple; grm_root is [] for unadjusted GRM
    // Should already contain only unrelated individuals if derived from filtered_grm
    tuple val(grm_name), path(grm_bin), path(grm_id), path(grm_details), path(grm_adjust), path(grm_root)
    path keep_file  // Optional: .keep file for sample filtering (use [] if GRM is already filtered)
    tuple val(phenotype_name), path(phenotype_file)
    path quant_covariates_file
    path cat_covariates_file

    output:
    tuple val(phenotype_name), path("pcgc_*.pcgc"), emit: pcgc_results
    path "pcgc_*.progress", optional: true, emit: pcgc_progress
    path "pcgc_*.*", emit: pcgc_all_outputs

    script:
    // Handle optional files: check if truthy (not empty list [])
    def quant_covar_param = quant_covariates_file ? "--covar ${quant_covariates_file}" : ''
    def cat_covar_param = cat_covariates_file ? "--factors ${cat_covariates_file}" : ''
    def keep_param = keep_file ? "--keep ${keep_file}" : ''
    def prevalence_param = params.ldak_pcgc_prevalence ? "--prevalence ${params.ldak_pcgc_prevalence}" : ''
    // Extract basename from grm_id for output file naming (in case grm_name is a full path)
    def grm_basename = grm_id.baseName.replace('.grm', '')
    def phenotype_slug = phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')

    """
    # Run LDAK PCGC regression for binary traits with adjusted GRM
    # Estimates heritability on liability scale using case-control data
    # If GRM is already filtered (unrelated individuals only), no --keep is needed
    # Note: grm_basename is extracted from grm_id filename to handle full path grm_name values
    ldak6 --pcgc pcgc_${phenotype_slug}_${grm_basename} \\
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
