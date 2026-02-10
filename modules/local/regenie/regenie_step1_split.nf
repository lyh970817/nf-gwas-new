process REGENIE_STEP1_SPLIT {

    input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_file), path(phenotypes_file), path(covariates_file), val(phenotype_name), val(is_binary)

    output:
    tuple path("chunks.master"), path("chunks*.snplist"), val(genotyped_plink_filename), path(genotyped_plink_file), path(phenotypes_file), path(covariates_file), val(phenotype_name), val(is_binary), emit: chunks
    path("chunks.master"), emit: master

    script:
    def covariants = covariates_file ? "--covarFile $covariates_file" : ''
    def quant_covariants = params.covariates_columns ? "--covarColList ${params.covariates_columns}" : ''
    def cat_covariants = params.covariates_cat_columns ? "--catCovarList ${params.covariates_cat_columns}" : ''
    def apply_rint = params.phenotypes_apply_rint ? "--apply-rint" : ''
    def forceStep1 = params.regenie_force_step1  ? "--force-step1" : ''
    def step1_optional = params.regenie_step1_optional  ? "$params.regenie_step1_optional":'' 
    def binary_trait = is_binary ? '--bt' : ''
  
    """
    # qcfiles path required for keep and extract (but not actually set below)
    regenie \
        --step 1 \
        --bed ${genotyped_plink_filename} \
        --phenoFile ${phenotypes_file} \
        --phenoColList ${phenotype_name} \
        $covariants \
        $quant_covariants \
        $cat_covariants \
        $apply_rint \
        $forceStep1 \
        --bsize ${params.regenie_bsize_step1} \
        --split-l0 chunks,${params.genotypes_prediction_chunks} \
        $binary_trait \
        --out chunks \
        $step1_optional
    """

}
