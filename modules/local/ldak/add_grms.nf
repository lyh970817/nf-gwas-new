process ADD_GRMS {
    tag "add_grms"
    publishDir "${params.pubDir}/ldak", mode: 'copy'

    input:
    path mgrm_file
    path grm_files  // All GRM files collected

    output:
    tuple val("ldak_grm"), path("ldak_grm.grm.bin"), path("ldak_grm.grm.id"), path("ldak_grm.grm.details"), path("ldak_grm.grm.adjust"), emit: combined_grm

    script:
    """
    # Run LDAK to add multiple GRMs
    ldak6 --add-grm ldak_grm --mgrm ${mgrm_file} --max-threads ${task.cpus}
    """
}
