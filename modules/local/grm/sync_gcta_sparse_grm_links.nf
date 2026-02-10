process SYNC_GCTA_SPARSE_GRM_LINKS {
    tag "sync_gcta_sparse_grm_${sparse_grm_id.baseName}"
    publishDir "${params.pubDir}/grm_links", mode: 'copy', pattern: '*.linked'
    label 'process_low'

    input:
    tuple path(sparse_grm_id), path(sparse_grm_sp)
    val(grm_dir)

    output:
    tuple path("*.linked"), emit: linked_marker
    tuple path("synced_*.grm.id"), path("synced_*.grm.sp"), emit: linked_grm

    script:
    def target_prefix = sparse_grm_id.baseName
    def target_dir = "${grm_dir}/gcta_grm_sparse"
    """
    mkdir -p "${target_dir}"

    ln -sfn "\$(realpath ${sparse_grm_id})" "${target_dir}/${target_prefix}.grm.id"
    ln -sfn "\$(realpath ${sparse_grm_sp})" "${target_dir}/${target_prefix}.grm.sp"

    ln -sfn "${target_dir}/${target_prefix}.grm.id" "synced_${target_prefix}.grm.id"
    ln -sfn "${target_dir}/${target_prefix}.grm.sp" "synced_${target_prefix}.grm.sp"

    echo "linked ${target_dir}/${target_prefix}" > "${target_prefix}.linked"
    """
}
