process MAKE_MGRM_LDAK {
    tag "make_mgrm_ldak"
    publishDir "${params.pubDir}/ldak", mode: 'copy', pattern: "*.mgrm"

    input:
    val grm_prefixes

    output:
    path "ldak_grm.mgrm", emit: mgrm_file

    script:
    """
    # Create a text file with the root names of all LDAK GRM files
    # Each line contains one GRM file root name
    touch ldak_grm.mgrm
    for prefix in ${grm_prefixes.join(' ')}; do
        echo "\$prefix" >> ldak_grm.mgrm
    done
    """
}
