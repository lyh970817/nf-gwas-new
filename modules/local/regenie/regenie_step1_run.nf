process REGENIE_STEP1_RUN {

    publishDir "${params.pubDir}/logs", mode: 'copy', pattern: 'regenie_step1_out.log'

    input:
    tuple val(genotyped_plink_filename), path(genotyped_plink_file)
    path phenotypes_file
    path covariates_file
    path condition_list_file

    output:
    path "regenie_step1_out*", emit: regenie_step1_out
    path "regenie_step1_out.log", emit: regenie_step1_out_log

    script:
    def covariants = covariates_file ? "--covarFile $covariates_file" : ''
    def quant_covariants = params.covariates_columns ? "--covarColList ${params.covariates_columns}" : ''
    def cat_covariants = params.covariates_cat_columns ? "--catCovarList ${params.covariates_cat_columns}" : ''
    def deleteMissings = params.phenotypes_delete_missings  ? "--strict" : ''
    def apply_rint = params.phenotypes_apply_rint ? "--apply-rint" : ''
    def forceStep1 = params.regenie_force_step1  ? "--force-step1" : ''
    def refFirst = params.regenie_ref_first  ? "--ref-first" : ''
    def condition_list = params.regenie_condition_list ? "--condition-list $condition_list_file" : ''
    def lowMemory = params.regenie_low_mem ? "--lowmem --lowmem-prefix tmp_rg" : ""
    def step1_optional = params.regenie_step1_optional  ? "$params.regenie_step1_optional":'' 

    """
    # qcfiles path required for keep and extract (but not actually set below)
    regenie \
        --step 1 \
        --bed ${genotyped_plink_filename} \
        --phenoFile ${phenotypes_file} \
        --phenoColList  ${params.phenotypes_columns} \
        $covariants \
        $quant_covariants \
        $cat_covariants \
        $condition_list \
        $deleteMissings \
        $apply_rint \
        $forceStep1 \
        $refFirst \
        --bsize ${params.regenie_bsize_step1} \
        ${params.phenotypes_binary_trait ? '--bt' : ''} \
        $lowMemory \
        --gz \
        --threads ${task.cpus} \
        --out regenie_step1_out \
        --use-relative-path \
        $step1_optional
  """
}
