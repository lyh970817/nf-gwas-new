process MERGE_MPFILES {
    input:
    path mpfile_parts

    output:
    path "gcta_grm.mpfile", emit: mpfile

    script:
    """
    cat ${mpfile_parts.join(' ')} > gcta_grm.mpfile
    """
}
