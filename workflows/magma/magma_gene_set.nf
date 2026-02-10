include { MAGMA_GENE_SET_ANALYSIS } from '../../modules/local/magma/magma_gene_set_analysis'

workflow MAGMA_GENE_SET {
    take:
    gene_results_ch      // tuple(trait_name, gene_results_file)
    set_annot_file       // path

    main:
    MAGMA_GENE_SET_ANALYSIS(
        gene_results_ch,
        set_annot_file
    )

    emit:
    geneset_results = MAGMA_GENE_SET_ANALYSIS.out.geneset_results
}
