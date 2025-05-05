process MERGE_SNP_GROUPS {
    tag "merge_group_${group}"

    input:
    tuple val(group), path(files)

    output:
    tuple val(group), path("snp_group${group}.txt"), emit: snps_to_extract

    script:
    """
    cat ${files.join(' ')} > snp_group${group}.txt
    """
}