/*
========================================================================================
    GCTA Filter GRM with Keep File Module
========================================================================================
    Purpose: Filter a GRM to include only individuals in a keep file
    - Used to ensure consistent samples across multiple SNP group GRMs
    - Apply the same keep file (from centralized relatedness filtering) to all GRMs

    Documentation: GCTA manual section on --keep
========================================================================================
*/

process FILTER_GRM_WITH_KEEP {
    tag "filter_grm_${snp_group}"
    publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "*.grm.*"

    input:
    tuple val(snp_group), val(prefix), path(grm_id), path(grm_bin), path(grm_n_bin)
    path keep_file

    output:
    tuple val(snp_group), val("${prefix}_unrel"), path("${prefix}_unrel.grm.id"), path("${prefix}_unrel.grm.bin"), path("${prefix}_unrel.grm.N.bin"), emit: filtered_grm

    script:
    """
    # Filter GRM to include only individuals in keep file
    # This ensures consistent samples across all SNP group GRMs
    gcta \\
        --grm ${prefix} \\
        --keep ${keep_file} \\
        --make-grm \\
        --out ${prefix}_unrel \\
        --thread-num ${task.cpus}
    """
}
