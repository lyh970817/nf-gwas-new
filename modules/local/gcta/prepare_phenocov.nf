process PREPARE_PHENOCOV {
    tag "${phenotypes_file.baseName}"

    input:
    tuple val(phenotype_name), path(phenotypes_file)
    path covariates_file

    output:
    tuple val(phenotype_name), path("${phenotypes_file.baseName}.noheader.txt"), emit: phenotypes_noheader
    path "*.quant.noheader.txt", optional: true, emit: covariates_quant_noheader
    path "*.cat.noheader.txt", optional: true, emit: covariates_cat_noheader

    script:
    def all_covariates = params.covariates_columns ? params.covariates_columns.split(',').collect{it.trim()} : []
    def cat_covariates = params.covariates_cat_columns ? params.covariates_cat_columns.split(',').collect{it.trim()} : []
    // Exclude categorical covariates from quantitative covariates
    def quant_covariates = all_covariates - cat_covariates
    // Handle optional covariates_file: if [] (empty list), use default name
    def covariates_basename = covariates_file ? covariates_file.baseName : 'covariates'

    """
    # Remove header from phenotypes file (skip first line)
    tail -n +2 ${phenotypes_file} > ${phenotypes_file.baseName}.noheader.txt

    # Process covariates file if provided (not empty list)
    if [ "${covariates_file}" != "" ] && [ -s "${covariates_file}" ]; then
        # Process covariates using R script
        if [ "${quant_covariates.size()}" -gt 0 ]; then
            # Extract quantitative covariates (all covariates excluding categorical ones)
            Rscript ${projectDir}/bin/extract_columns.R ${covariates_file} "${quant_covariates.join(',')}" temp_quant.txt temp_unused.txt

            # Remove header from quantitative covariates file
            tail -n +2 temp_quant.txt > ${covariates_basename}.quant.noheader.txt
            rm temp_quant.txt temp_unused.txt
        fi

        if [ "${cat_covariates.size()}" -gt 0 ]; then
            # Extract categorical covariates
            Rscript ${projectDir}/bin/extract_columns.R ${covariates_file} "${cat_covariates.join(',')}" temp_cat.txt temp_unused.txt

            # Remove header from categorical covariates file
            tail -n +2 temp_cat.txt > ${covariates_basename}.cat.noheader.txt
            rm temp_cat.txt temp_unused.txt
        fi
    fi
    """
}
