process PREPARE_PHENOCOV_BIVARIATE {
    tag "bivariate_${phenotype1_name}_${phenotype2_name}"

    input:
    tuple path(phenotype1_file), path(phenotype2_file), path(covariates_file), val(phenotype1_name), val(phenotype2_name), val(pair_name)

    output:
    tuple val(pair_name), path("phenotypes_bivariate.txt"), emit: phenotypes_file
    path "mpheno_indices.txt", emit: mpheno_indices
    path "*.quant.noheader.txt", optional: true, emit: covariates_quant_noheader
    path "*.cat.noheader.txt", optional: true, emit: covariates_cat_noheader

    script:
    def all_covariates = params.covariates_columns ? params.covariates_columns.split(',').collect{it.trim()} : []
    def cat_covariates = params.covariates_cat_columns ? params.covariates_cat_columns.split(',').collect{it.trim()} : []
    def quant_covariates = all_covariates - cat_covariates
    def covariates_basename = covariates_file ? covariates_file.baseName : 'covariates'

    """
    # Prepare bivariate phenotype file using R script
    # Extracts FID, IID, phenotype1, phenotype2 in GCTA format (no header)
    Rscript ${projectDir}/bin/prepare_bivariate_phenotypes.R \\
        ${phenotype1_file} \\
        ${phenotype2_file} \\
        "${phenotype1_name}" \\
        "${phenotype2_name}" \\
        phenotypes_bivariate.txt \\
        mpheno_indices.txt

    # Process covariates file if provided (not empty list)
    if [ "${covariates_file}" != "" ] && [ -s "${covariates_file}" ]; then
        # Process quantitative covariates
        if [ "${quant_covariates.size()}" -gt 0 ]; then
            Rscript ${projectDir}/bin/extract_columns.R \\
                ${covariates_file} \\
                "${quant_covariates.join(',')}" \\
                temp_quant.txt \\
                temp_unused.txt

            # Remove header from quantitative covariates file
            tail -n +2 temp_quant.txt > ${covariates_basename}.quant.noheader.txt
            rm temp_quant.txt temp_unused.txt
        fi

        # Process categorical covariates
        if [ "${cat_covariates.size()}" -gt 0 ]; then
            Rscript ${projectDir}/bin/extract_columns.R \\
                ${covariates_file} \\
                "${cat_covariates.join(',')}" \\
                temp_cat.txt \\
                temp_unused.txt

            # Remove header from categorical covariates file
            tail -n +2 temp_cat.txt > ${covariates_basename}.cat.noheader.txt
            rm temp_cat.txt temp_unused.txt
        fi
    fi
    """
}
