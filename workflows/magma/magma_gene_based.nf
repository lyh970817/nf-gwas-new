include { PREPARE_MAGMA_PVAL_INPUT } from '../../modules/local/magma/prepare_magma_pval_input'
include { MAGMA_ANNOTATE } from '../../modules/local/magma/magma_annotate'
include { MAGMA_GENE_ANALYSIS } from '../../modules/local/magma/magma_gene_analysis'

workflow MAGMA_GENE_BASED {
    take:
    summary_stats_ch        // tuple(trait_name, summary_stats_file)
    reference_plink_ch      // tuple(reference_prefix, bed, bim, fam)
    gene_annot_file         // path or []
    gene_loc_file           // path or []

    main:
    PREPARE_MAGMA_PVAL_INPUT(summary_stats_ch)

    gene_annot_for_analysis_ch = Channel.empty()

    if (gene_annot_file != []) {
        gene_annot_for_analysis_ch = Channel.of(gene_annot_file)
    } else {
        MAGMA_ANNOTATE(
            reference_plink_ch,
            gene_loc_file
        )
        gene_annot_for_analysis_ch = MAGMA_ANNOTATE.out.gene_annotation
    }

    reference_and_annot_ch = reference_plink_ch
        .combine(gene_annot_for_analysis_ch)
        .map { reference_prefix, bed, bim, fam, gene_annot ->
            tuple(reference_prefix, bed, bim, fam, gene_annot)
        }

    gene_analysis_inputs = PREPARE_MAGMA_PVAL_INPUT.out.magma_pval_input
        .combine(reference_and_annot_ch)
        .map { trait_name, magma_pval_file, reference_prefix, bed, bim, fam, gene_annot ->
            tuple(trait_name, magma_pval_file, reference_prefix, bed, bim, fam, gene_annot)
        }

    MAGMA_GENE_ANALYSIS(gene_analysis_inputs)

    emit:
    magma_pval_input = PREPARE_MAGMA_PVAL_INPUT.out.magma_pval_input
    gene_annotation = gene_annot_for_analysis_ch
    gene_results = MAGMA_GENE_ANALYSIS.out.gene_results
    gene_results_raw = MAGMA_GENE_ANALYSIS.out.gene_results_raw
}
