/*
========================================================================================
    LDAK-KVIK Merge Results: Combine Per-Chromosome Step 2 Results
========================================================================================

    Purpose: Merge per-chromosome association results from Step 2 into genome-wide files

    When running Step 2 per-chromosome for parallelization, results need to be
    merged into final genome-wide output files.

    Documentation: docs/external/ldak-kvik/ukbrap/running.md
========================================================================================
*/

process MERGE_KVIK_RESULTS {
    tag "merge_kvik_results_${phenotype_name}"
    publishDir "${params.pubDir}/ldak/kvik", mode: 'copy'

    label 'process_low'

    input:
    // Collected association files from all chromosomes
    tuple path(assoc_files), path(summaries_files), val(phenotype_name)

    output:
    tuple val(phenotype_name), path { "kvik_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.step2.assoc" }, emit: merged_assoc
    tuple val(phenotype_name), path { "kvik_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.step2.summaries" }, emit: merged_summaries
    tuple val(phenotype_name), path { "kvik_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.step2.pvalues" }, emit: merged_pvalues, optional: true

    script:
    def phenotype_slug = phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')
    def target_prefix = "kvik_${phenotype_slug}"
    def source_prefix = assoc_files[0].name.replaceAll(/\.step2\.chr[0-9]+\.assoc$/, '')

    """
    # Merge per-chromosome association results
    # Combine header from first file with data from all files

    # Merge .assoc files
    # Get header from first file
    head -n 1 \$(ls ${source_prefix}.step2.chr*.assoc | sort -V | head -n 1) > ${target_prefix}.step2.assoc

    # Append data from all files (skip header)
    for f in \$(ls ${source_prefix}.step2.chr*.assoc | sort -V); do
        tail -n +2 "\$f" >> ${target_prefix}.step2.assoc
    done

    # Merge .summaries files (if they exist)
    if ls ${source_prefix}.step2.chr*.summaries 1>/dev/null 2>&1; then
        head -n 1 \$(ls ${source_prefix}.step2.chr*.summaries | sort -V | head -n 1) > ${target_prefix}.step2.summaries
        for f in \$(ls ${source_prefix}.step2.chr*.summaries | sort -V); do
            tail -n +2 "\$f" >> ${target_prefix}.step2.summaries
        done
    else
        touch ${target_prefix}.step2.summaries
    fi

    # Merge .pvalues files (if they exist)
    if ls ${source_prefix}.step2.chr*.pvalues 1>/dev/null 2>&1; then
        head -n 1 \$(ls ${source_prefix}.step2.chr*.pvalues | sort -V | head -n 1) > ${target_prefix}.step2.pvalues
        for f in \$(ls ${source_prefix}.step2.chr*.pvalues | sort -V); do
            tail -n +2 "\$f" >> ${target_prefix}.step2.pvalues
        done
    fi
    """
}
