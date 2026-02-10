process MAGMA_ANNOTATE {
    tag "magma_annotate"
    publishDir "${params.pubDir}/magma/annot", mode: 'copy'
    label 'process_low'

    input:
    tuple val(reference_prefix), path(ref_bed), path(ref_bim), path(ref_fam)
    path(gene_loc_file)

    output:
    path "magma_genes.annot", emit: gene_annotation
    path "magma_annotate.log", emit: log

    script:
    def up = params.magma_window_up_kb ?: 35
    def down = params.magma_window_down_kb ?: 10
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
        --annotate window=${up},${down} \
        --snp-loc ${local_ref_prefix}.bim \
        --gene-loc ${gene_loc_file} \
        --out magma_genes \
        2>&1 | tee magma_annotate.log

    mv magma_genes.genes.annot magma_genes.annot
    """
}
