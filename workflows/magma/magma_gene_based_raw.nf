include { MAGMA_ANNOTATE } from '../../modules/local/magma/magma_annotate'
include { MAGMA_GENE_ANALYSIS_RAW } from '../../modules/local/magma/magma_gene_analysis_raw'
include { MERGE_MAGMA_RAW_RESULTS as MERGE_MAGMA_RAW_OUT } from '../../modules/local/magma/merge_magma_raw_results'
include { MERGE_MAGMA_RAW_RESULTS as MERGE_MAGMA_RAW_RAW } from '../../modules/local/magma/merge_magma_raw_results'

workflow MAGMA_GENE_BASED_RAW {
    take:
    phenotype_meta_ch      // tuple(trait_name, phenotypes_file, is_binary)
    raw_plink_ch           // tuple(raw_prefix, bed, bim, fam)
    gene_annot_file        // path or []
    gene_loc_file          // path or []
    covariates_file        // path or []

    main:
    gene_annot_for_analysis_ch = Channel.empty()

    if (gene_annot_file != []) {
        gene_annot_for_analysis_ch = Channel.of(gene_annot_file)
    } else {
        MAGMA_ANNOTATE(
            raw_plink_ch,
            gene_loc_file
        )
        gene_annot_for_analysis_ch = MAGMA_ANNOTATE.out.gene_annotation
    }

    raw_and_annot_ch = raw_plink_ch
        .combine(gene_annot_for_analysis_ch)
        .map { raw_prefix, bed, bim, fam, gene_annot ->
            tuple(raw_prefix, bed, bim, fam, gene_annot)
        }

    gene_analysis_inputs = phenotype_meta_ch
        .combine(raw_and_annot_ch)
        .map { trait_name, phenotypes_file, is_binary, raw_prefix, bed, bim, fam, gene_annot ->
            def raw_slug = raw_prefix.replaceAll(/[^A-Za-z0-9._-]+/, '_')
            def trait_batch_name = "${trait_name}___BATCH___${raw_slug}"
            tuple(trait_batch_name, phenotypes_file, raw_prefix, bed, bim, fam, gene_annot, covariates_file)
        }

    MAGMA_GENE_ANALYSIS_RAW(gene_analysis_inputs)

    merged_gene_inputs = MAGMA_GENE_ANALYSIS_RAW.out.gene_results
        .map { trait_batch_name, gene_out ->
            def trait_name = trait_batch_name.replaceFirst(/___BATCH___.*/, '')
            tuple(trait_name, gene_out)
        }
        .groupTuple()
        .map { trait_name, files -> tuple(trait_name, files, 'out') }

    merged_raw_inputs = MAGMA_GENE_ANALYSIS_RAW.out.gene_results_raw
        .map { trait_batch_name, gene_raw ->
            def trait_name = trait_batch_name.replaceFirst(/___BATCH___.*/, '')
            tuple(trait_name, gene_raw)
        }
        .groupTuple()
        .map { trait_name, files -> tuple(trait_name, files, 'raw') }

    MERGE_MAGMA_RAW_OUT(merged_gene_inputs)
    MERGE_MAGMA_RAW_RAW(merged_raw_inputs)

    emit:
    gene_annotation = gene_annot_for_analysis_ch
    gene_results = MERGE_MAGMA_RAW_OUT.out.merged_results
    gene_results_raw = MERGE_MAGMA_RAW_RAW.out.merged_results
}
