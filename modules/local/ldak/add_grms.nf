process ADD_GRMS {
    tag "add_grms"
    publishDir "${params.pubDir}/ldak", mode: 'copy'

    input:
    path mgrm_file
    path grm_files  // All GRM files collected
    val output_name

    output:
    tuple val("${output_name}"), path("${output_name}.grm.bin"), path("${output_name}.grm.id"), path("${output_name}.grm.details"), path("${output_name}.grm.adjust"), emit: combined_grm

    script:
    """
    # Run LDAK to add multiple GRMs
    ldak6 --add-grm ${output_name} --mgrm ${mgrm_file} --max-threads ${task.cpus}
    """
}
