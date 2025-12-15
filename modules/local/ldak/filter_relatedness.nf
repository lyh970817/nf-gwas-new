process FILTER_RELATEDNESS {
    tag "filter_relatedness_${grm_name}"
    publishDir "${params.pubDir}/ldak", mode: 'copy'

    input:
    tuple val(grm_name), path(grm_bin_file), path(grm_id_file), path(grm_details_file), path(grm_adjust_file)

    output:
    // Filtered list files (for reference/debugging)
    tuple val(grm_name), path("${grm_name}.keep"), path("${grm_name}.lose"), path("${grm_name}.maxrel"), emit: filtered_list
    // Filtered GRM containing only unrelated individuals
    tuple val("${grm_name}_unrel"), path("${grm_name}_unrel.grm.bin"), path("${grm_name}_unrel.grm.id"), path("${grm_name}_unrel.grm.details"), path("${grm_name}_unrel.grm.adjust"), emit: filtered_grm

    script:
    """
    # Step 1: Run LDAK to identify related individuals
    # Output files: .keep (unrelated), .lose (related), .maxrel (max kinship found)
    ldak6 --filter ${grm_name} --grm ${grm_name} --max-threads ${task.cpus}

    # Step 2: Create a subset GRM containing only unrelated individuals
    # Uses the .keep file from Step 1 to filter the GRM
    ldak6 --sub-grm ${grm_name}_unrel --grm ${grm_name} --keep ${grm_name}.keep --max-threads ${task.cpus}
    """
}
