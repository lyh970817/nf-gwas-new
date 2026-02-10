process MERGE_MAGMA_RAW_RESULTS {
    tag "merge_magma_raw_${trait_name}_${suffix}"
    publishDir "${params.pubDir}/magma/gene", mode: 'copy'
    label 'process_low'

    input:
    tuple val(trait_name), path(result_files), val(suffix)

    output:
    tuple val(trait_name), path("${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.genes.${suffix}"), emit: merged_results

    script:
    def trait_slug = trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')

    """
    first_file=\$(ls *.genes.${suffix} | head -n 1)
    head -n 1 "\$first_file" > ${trait_slug}.genes.${suffix}

    for f in \$(ls *.genes.${suffix} | sort -V); do
        tail -n +2 "\$f" >> ${trait_slug}.genes.${suffix}
    done
    """
}
