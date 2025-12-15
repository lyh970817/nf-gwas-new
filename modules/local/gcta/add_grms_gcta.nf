/*
========================================================================================
    GCTA Add GRMs Module
========================================================================================
    Purpose: Combine multiple GRMs into a single GRM
    - Used for centralized relatedness filtering in GCTA GRM LDMS workflow
    - Combines GRMs from different SNP groups into one for consistent sample filtering
    - Uses GCTA --mgrm --make-grm functionality

    Documentation: GCTA manual section on --mgrm
========================================================================================
*/

process ADD_GRMS_GCTA {
    tag "add_grms_gcta"
    publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "combined_grm.*"

    input:
    path mgrm_file
    path grm_files  // All GRM files (.grm.id, .grm.bin, .grm.N.bin) collected

    output:
    tuple val("combined_grm"), path("combined_grm.grm.id"), path("combined_grm.grm.bin"), path("combined_grm.grm.N.bin"), emit: combined_grm

    script:
    """
    # Combine multiple GRMs into a single GRM using GCTA
    # The mgrm_file contains one GRM prefix per line
    gcta \\
        --mgrm ${mgrm_file} \\
        --make-grm \\
        --out combined_grm \\
        --thread-num ${task.cpus}
    """
}
