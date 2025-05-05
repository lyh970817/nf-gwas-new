process MAKE_BK_SPARSE {
    tag "make_bk_sparse"
    publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "${prefix}_sp.*"

    input:
    tuple val(snp_group), val(prefix), path(grm_ids), path(grm_bins), path(grm_n_bins)
    val cutoff

    output:
    tuple path("${prefix}_sp.grm.id"),
          path("${prefix}_sp.grm.sp"), emit: sparse_grm_files

    script:
    """
    # Create sparse GRM with specified cutoff
    gcta \\
        --grm ${prefix} \\
        --make-bK-sparse ${cutoff} \\
        --out ${prefix}_sp
    """
}
