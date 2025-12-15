process REMOVE_RELATED_SUBJECTS {
    tag "remove_related_subjects_${prefix}"
    publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "*.grm.*"
    publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "*.keep"

    input:
    tuple val(snp_group), val(prefix), path(grm_ids), path(grm_bins), path(grm_n_bins)

    output:
    tuple val(snp_group), val("${prefix}_unrel05"), path("${prefix}_unrel05.grm.id"), path("${prefix}_unrel05.grm.bin"), path("${prefix}_unrel05.grm.N.bin"), emit: grm_files
    path "${prefix}_unrel05.grm.id", emit: keep_file  // The .grm.id file can be used as a keep file

    script:
    """
    # Remove related subjects using grm-cutoff 0.05
    # The output .grm.id file contains the list of unrelated individuals
    # which can be used as a keep file for filtering other GRMs
    gcta \\
        --grm ${prefix} \\
        --grm-cutoff 0.05 \\
        --make-grm \\
        --out ${prefix}_unrel05
    """
}
