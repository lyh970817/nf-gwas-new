process FILTER_RELATEDNESS {
    tag "filter_relatedness"
    publishDir "${params.pubDir}/ldak", mode: 'copy'

    input:
    tuple val(grm_name), path(grm_bin_file), path(grm_id_file), path(grm_details_file), path(grm_adjust_file)

    output:
    tuple val("ldak_grm_filtered"), path("ldak_grm_filtered.keep"), path("ldak_grm_filtered.lose"), path("ldak_grm_filtered.maxrel"), emit: filtered_list

    script:
    """
    # Run LDAK to filter related individuals from the GRM
    ldak6 --filter ldak_grm_filtered --grm ${grm_name} --max-threads ${task.cpus}
    """
}
