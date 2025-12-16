/*
========================================================================================
    LDAK-KVIK Merge Results: Combine Per-Chromosome Step 2 Results
========================================================================================

    Purpose: Merge per-chromosome association results from Step 2 into genome-wide files

    When running Step 2 per-chromosome for parallelization, results need to be
    merged before Step 3 (gene-based analysis) or final output.

    Documentation: docs/external/ldak-kvik/ukbrap/running.md
========================================================================================
*/

process MERGE_KVIK_RESULTS {
    tag "merge_kvik_results_${phenotype_name}"
    publishDir "${params.pubDir}/ldak/kvik", mode: 'copy'

    label 'process_low'

    input:
    // Collected association files from all chromosomes
    path assoc_files           // List of kvik.step2.chr*.assoc files
    // Collected summaries files from all chromosomes (for Step 3)
    path summaries_files       // List of kvik.step2.chr*.summaries files
    val phenotype_name         // For output naming

    output:
    path "kvik.step2.assoc", emit: merged_assoc
    path "kvik.step2.summaries", emit: merged_summaries
    path "kvik.step2.pvalues", emit: merged_pvalues, optional: true

    script:
    """
    # Merge per-chromosome association results
    # Combine header from first file with data from all files

    # Merge .assoc files
    # Get header from first file
    head -n 1 \$(ls kvik.step2.chr*.assoc | sort -V | head -n 1) > kvik.step2.assoc

    # Append data from all files (skip header)
    for f in \$(ls kvik.step2.chr*.assoc | sort -V); do
        tail -n +2 "\$f" >> kvik.step2.assoc
    done

    # Merge .summaries files (if they exist)
    if ls kvik.step2.chr*.summaries 1>/dev/null 2>&1; then
        head -n 1 \$(ls kvik.step2.chr*.summaries | sort -V | head -n 1) > kvik.step2.summaries
        for f in \$(ls kvik.step2.chr*.summaries | sort -V); do
            tail -n +2 "\$f" >> kvik.step2.summaries
        done
    else
        touch kvik.step2.summaries
    fi

    # Merge .pvalues files (if they exist)
    if ls kvik.step2.chr*.pvalues 1>/dev/null 2>&1; then
        head -n 1 \$(ls kvik.step2.chr*.pvalues | sort -V | head -n 1) > kvik.step2.pvalues
        for f in \$(ls kvik.step2.chr*.pvalues | sort -V); do
            tail -n +2 "\$f" >> kvik.step2.pvalues
        done
    fi
    """
}
