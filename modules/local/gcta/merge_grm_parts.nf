process MERGE_GRM_PARTS {
    tag "merge ${nparts_gcta} parts"
    publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "gcta_grm.*"

    input:
    tuple val(nparts_gcta), val(snp_group), path(grm_ids), path(grm_bins), path(grm_n_bins)

    output:
    tuple val(snp_group), val("gcta_grm_${snp_group}"), path("gcta_grm_${snp_group}.grm.id"), path("gcta_grm_${snp_group}.grm.bin"), path("gcta_grm_${snp_group}.grm.N.bin"), emit: grm_files

    script:
    """
    cat gcta_grm_${snp_group}.part_${nparts_gcta}_*.grm.id    > gcta_grm_${snp_group}.grm.id
    cat gcta_grm_${snp_group}.part_${nparts_gcta}_*.grm.bin   > gcta_grm_${snp_group}.grm.bin
    cat gcta_grm_${snp_group}.part_${nparts_gcta}_*.grm.N.bin > gcta_grm_${snp_group}.grm.N.bin
    """
}
