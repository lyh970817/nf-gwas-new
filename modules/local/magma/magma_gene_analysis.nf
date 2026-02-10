process MAGMA_GENE_ANALYSIS {
    tag "magma_gene_${trait_name}"
    publishDir "${params.pubDir}/magma/gene", mode: 'copy'
    label 'process_medium'

    input:
    tuple val(trait_name), path(magma_pval_file), val(reference_prefix), path(ref_bed), path(ref_bim), path(ref_fam), path(gene_annot_file)

    output:
    tuple val(trait_name), path { "${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.genes.out" }, emit: gene_results
    tuple val(trait_name), path { "${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.genes.raw" }, emit: gene_results_raw
    path { "${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.gene.log" }, emit: log

    script:
    def trait_slug = trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')

    def pval_args = []
    if (params.sumstats_snp_col && params.sumstats_p_col) {
        pval_args << "use=${params.sumstats_snp_col},${params.sumstats_p_col}"
    }
    if (params.sumstats_n != null) {
        pval_args << "N=${params.sumstats_n}"
    } else if (params.sumstats_n_col) {
        pval_args << "ncol=${params.sumstats_n_col}"
    }
    def pval_arg_string = pval_args.isEmpty() ? "" : pval_args.join(' ')

    def gene_model = params.magma_gene_model ? "--model ${params.magma_gene_model}" : ""
    def gene_extra = params.magma_gene_extra_args ? params.magma_gene_extra_args.toString() : ""
    def local_ref_prefix = 'magma_ref'

    """
    cp ${ref_bed} ${local_ref_prefix}.bed
    cp ${ref_bim} ${local_ref_prefix}.bim
    cp ${ref_fam} ${local_ref_prefix}.fam

    MAGMA_BIN="magma"
    if [[ -x ./magma ]]; then
        MAGMA_BIN="./magma"
    fi

    "\${MAGMA_BIN}" \
        --bfile ${local_ref_prefix} \
        --gene-annot ${gene_annot_file} \
        --pval ${magma_pval_file} ${pval_arg_string} \
        ${gene_model} \
        ${gene_extra} \
        --out ${trait_slug} \
        2>&1 | tee ${trait_slug}.gene.log
    """
}
