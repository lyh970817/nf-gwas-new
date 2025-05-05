process REMOVE_RELATED_SUBJECTS {
    tag "remove_related_subjects"
    publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "gcta_grm_adj_unrel05.*"

    input:
    tuple val(snp_group), val(prefix), path(grm_ids), path(grm_bins), path(grm_n_bins)

    output:
    tuple val(snp_group), val("${prefix}_unrel05"), path("${prefix}_unrel05.grm.id"), path("${prefix}_unrel05.grm.bin"), path("${prefix}_unrel05.grm.N.bin"), emit: grm_files

    script:
    """
    # Remove related subjects using grm-cutoff 0.05
    gcta \\
        --grm ${prefix} \\
        --grm-cutoff 0.05 \\
        --make-grm \\
        --out ${prefix}_unrel05
    """
}
