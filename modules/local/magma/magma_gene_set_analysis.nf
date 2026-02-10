process MAGMA_GENE_SET_ANALYSIS {
    tag "magma_geneset_${trait_name}"
    publishDir "${params.pubDir}/magma/geneset", mode: 'copy'
    label 'process_medium'

    input:
    tuple val(trait_name), path(gene_results_file)
    path(set_annot_file)

    output:
    tuple val(trait_name), path { "${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.gsa.out" }, emit: geneset_results
    path { "${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.geneset.log" }, emit: log

    script:
    def trait_slug = trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')
    def set_model = params.magma_set_model ? "--model ${params.magma_set_model}" : ""
    def set_extra = params.magma_set_extra_args ? params.magma_set_extra_args.toString() : ""

    """
    MAGMA_BIN="magma"
    if [[ -x ./magma ]]; then
        MAGMA_BIN="./magma"
    fi

    "\${MAGMA_BIN}" \
        --gene-results ${gene_results_file} \
        --set-annot ${set_annot_file} \
        ${set_model} \
        ${set_extra} \
        --out ${trait_slug} \
        2>&1 | tee ${trait_slug}.geneset.log
    """
}
