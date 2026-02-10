process MAGMA_GENE_ANALYSIS_RAW {
    tag "magma_gene_raw_${trait_name}"
    publishDir "${params.pubDir}/magma/gene", mode: 'copy'
    label 'process_medium'

    input:
    tuple val(trait_name), path(phenotypes_file), val(raw_prefix), path(raw_bed), path(raw_bim), path(raw_fam), path(gene_annot_file), path(covariates_file)

    output:
    tuple val(trait_name), path { "${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.genes.out" }, emit: gene_results
    tuple val(trait_name), path { "${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.genes.raw" }, emit: gene_results_raw
    path { "${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.gene.log" }, emit: log

    script:
    def trait_slug = trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')
    def local_raw_prefix = 'magma_raw'

    def pheno_arg = "--pheno file=${phenotypes_file} use=${trait_name}"

    def covar_arg = ''
    if (covariates_file) {
        covar_arg = "--covar file=${covariates_file}"
        if (params.covariates_columns) {
            covar_arg += " use=${params.covariates_columns}"
        }
    }

    def gene_model = params.magma_gene_model ? "--model ${params.magma_gene_model}" : ""
    def raw_extra = params.magma_raw_extra_args ? params.magma_raw_extra_args.toString() : ""

    """
    cp ${raw_bed} ${local_raw_prefix}.bed
    cp ${raw_bim} ${local_raw_prefix}.bim
    cp ${raw_fam} ${local_raw_prefix}.fam

    MAGMA_BIN="magma"
    if [[ -x ./magma ]]; then
        MAGMA_BIN="./magma"
    fi

    "\${MAGMA_BIN}" \
        --bfile ${local_raw_prefix} \
        --gene-annot ${gene_annot_file} \
        ${pheno_arg} \
        ${covar_arg} \
        ${gene_model} \
        ${raw_extra} \
        --out ${trait_slug} \
        2>&1 | tee ${trait_slug}.gene.log
    """
}
