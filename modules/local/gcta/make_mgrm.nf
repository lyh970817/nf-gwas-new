process MAKE_MGRM {
    tag "make_mgrm"
    publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "*.mgrm"

    input:
    val grm_prefixes

    output:
    path "gcta_grm.mgrm", emit: mgrm_file

    script:
    """
    # Create a text file with the root names of all GRM files
    # Each line contains one GRM file root name
    touch gcta_grm.mgrm
    for prefix in ${grm_prefixes.join(' ')}; do
        echo "\$prefix" >> gcta_grm.mgrm
    done
    """
}
