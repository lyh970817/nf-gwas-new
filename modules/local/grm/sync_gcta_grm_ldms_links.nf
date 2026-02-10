process SYNC_GCTA_GRM_LDMS_LINKS {
    tag "sync_gcta_grm_ldms_${prefix}"
    publishDir "${params.pubDir}/grm_links", mode: 'copy', pattern: '*.linked'
    label 'process_low'

    input:
    tuple val(snp_group), val(prefix), path(grm_id), path(grm_bin), path(grm_n_bin)
    val(grm_dir)

    output:
    tuple val(snp_group), val(prefix), path("*.linked"), emit: linked_marker
    tuple val(snp_group), val(prefix), path("synced_*.grm.id"), path("synced_*.grm.bin"), path("synced_*.grm.N.bin"), emit: linked_grm

    script:
    def target_prefix = prefix.tokenize('/').last()
    def target_dir = "${grm_dir}/gcta_grm_ldms"
    """
    mkdir -p "${target_dir}"

    ln -sfn "\$(realpath ${grm_id})" "${target_dir}/${target_prefix}.grm.id"
    ln -sfn "\$(realpath ${grm_bin})" "${target_dir}/${target_prefix}.grm.bin"
    ln -sfn "\$(realpath ${grm_n_bin})" "${target_dir}/${target_prefix}.grm.N.bin"

    {
        for id_file in "${target_dir}"/*.grm.id; do
            [[ -e "\${id_file}" ]] || continue
            basename "\${id_file}" .grm.id
        done | sort -u
    } > "${target_dir}/gcta_grm_ldms.mgrm"

    ln -sfn "${target_dir}/${target_prefix}.grm.id" "synced_${target_prefix}.grm.id"
    ln -sfn "${target_dir}/${target_prefix}.grm.bin" "synced_${target_prefix}.grm.bin"
    ln -sfn "${target_dir}/${target_prefix}.grm.N.bin" "synced_${target_prefix}.grm.N.bin"

    echo "linked ${target_dir}/${target_prefix}" > "${target_prefix}.linked"
    """
}
