process ADJUST_GRM {
    tag "adjust_grm"
    publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "gcta_grm_adj.*"

    input:
    tuple val(snp_group), val(prefix), path(grm_ids), path(grm_bins), path(grm_n_bins)

    output:
    tuple val(snp_group), val("${prefix}_adj"), path("${prefix}_adj.grm.id"), path("${prefix}_adj.grm.bin"), path("${prefix}_adj.grm.N.bin"), emit: grm_files

    script:
    """
    # Adjust for incomplete tagging of causal SNPs
    gcta \\
        --grm ${prefix} \\
        --grm-adj 0 \\
        --make-grm \\
        --out ${prefix}_adj
    """
}
