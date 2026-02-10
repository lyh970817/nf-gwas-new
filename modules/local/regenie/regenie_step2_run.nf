process REGENIE_STEP2_RUN {

    publishDir "${params.pubDir}/logs", mode: 'copy', pattern: '*.log'

    tag "${plink1_bed_file.simpleName}"

    input:
    tuple path(step1_out), val(chr_num), val(filename), path(plink1_bed_file), path(plink1_bim_file), path(plink1_fam_file), val(range), val(assoc_format), path(phenotypes_file), path(covariates_file), val(phenotype_name), val(is_binary)

    output:
    tuple val(filename), path("*regenie.gz"), emit: regenie_step2_out
    path "*regenie.Ydict", emit: regenie_step2_ydict, optional: true
    path "${filename}*.log", emit: regenie_step2_out_log

    script:
    def format = '--bed'
    def extension = ''
    def bgen_sample = ''
    def test = "--test $params.regenie_test"
    def firthApprox = params.regenie_firth_approx ? "--approx" : ""
    def firth = params.regenie_firth ? "--firth $firthApprox" : ""
    def binaryTrait =  is_binary ? "--bt $firth " : ""
    def covariants = covariates_file ? "--covarFile $covariates_file" : ''
    def quant_covariants = params.covariates_columns ? "--covarColList ${params.covariates_columns}" : ''
    def cat_covariants = params.covariates_cat_columns ? "--catCovarList ${params.covariates_cat_columns}" : ''
    def predictions = params.regenie_skip_predictions  ? '--ignore-pred' : ""
    def pred_list = params.regenie_skip_predictions ? '' : '--pred regenie_step1_out_pred.list'
    def apply_rint = params.phenotypes_apply_rint ? "--apply-rint" : ''
    // Only use --range if a proper range string is provided (format: CHR:START-END)
    // The 'range' input variable contains the range string, or -1 if not specified
    // Note: chr_num is just a sequential index, not suitable for --range
    def range_output = (chr_num != -1) ? chr_num.toString().replaceAll(":", "-"):''
    def regenie_range = (range != -1 && range != null && range.toString() != '-1') ? "--range ${range}" : ''
    def output_name = (chr_num != -1) ? "${filename}-${range_output}" : "$filename"
    // Without --no-split, REGENIE creates separate files per phenotype: output_PHENO.regenie.gz
    def step2_optional = params.regenie_step2_optional  ? "$params.regenie_step2_optional":''

    """
    regenie \
        --step 2 \
        $format ${filename}${extension} \
        --phenoFile ${phenotypes_file} \
        --phenoColList ${phenotype_name} \
        --bsize ${params.regenie_bsize_step2} \
        $pred_list \
        --threads ${task.cpus} \
        --gz \
        $binaryTrait \
        $test \
        $bgen_sample \
        $regenie_range \
        $covariants \
        $quant_covariants \
        $cat_covariants \
        $predictions \
        $apply_rint \
        --out $output_name \
        $step2_optional
    """
}
