process RUN_FASTGWA_MLM {
    tag "fastGWA_mlm_${filename}"
    publishDir "${params.pubDir}/gcta_fastgwa", mode: 'copy', pattern: "*.fastGWA"

    input:
    tuple val(chr_num), val(filename), path(plink_pgen), path(plink_psam), path(plink_pvar), val(range)
    tuple path(sparse_grm_id), path(sparse_grm_sp)
    path phenotypes_file
    path qcovariates_file
    path covariates_file

    output:
    path "*.fastGWA", emit: fastgwa_results

    script:
    def qcovar_param = qcovariates_file ? "--qcovar ${qcovariates_file}" : ''
    def covar_param = covariates_file ? "--covar ${covariates_file}" : ''
    def grm_sparse_prefix = sparse_grm_id.baseName.split("\\.")[0]
    def out = "${filename}_${phenotypes_file.baseName}"

    """
    # Run GCTA fastgeWA-mlm analysis
    gcta \\
        --pfile ${filename} \\
        --grm-sparse ${grm_sparse_prefix} \\
        --fastGWA-mlm \\
        --pheno ${phenotypes_file} \\
        ${qcovar_param} \\
        ${covar_param} \\
        --thread-num ${task.cpus} \\
        --out ${out}
    """
}
