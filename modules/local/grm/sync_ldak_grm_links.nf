process SYNC_LDAK_GRM_LINKS {
    tag "sync_ldak_grm_${grm_name}"
    publishDir "${params.pubDir}/grm_links", mode: 'copy', pattern: '*.linked'
    label 'process_low'

    input:
    tuple val(grm_name), path(grm_bin), path(grm_id), path(grm_details), path(grm_adjust), path(keep_file)
    val(grm_dir)

    output:
    tuple val(grm_name), path("*.linked"), emit: linked_marker
    tuple val(grm_name), path("synced_*.grm.bin"), path("synced_*.grm.id"), path("synced_*.grm.details"), path("synced_*.grm.adjust"), path("synced_*.keep"), emit: linked_grm

    script:
    def target_prefix = grm_name.tokenize('/').last()
    def target_dir = "${grm_dir}/ldak_grm"
    """
    mkdir -p "${target_dir}"

    ln -sfn "\$(realpath ${grm_bin})" "${target_dir}/${target_prefix}.grm.bin"
    ln -sfn "\$(realpath ${grm_id})" "${target_dir}/${target_prefix}.grm.id"
    ln -sfn "\$(realpath ${grm_details})" "${target_dir}/${target_prefix}.grm.details"
    ln -sfn "\$(realpath ${grm_adjust})" "${target_dir}/${target_prefix}.grm.adjust"
    ln -sfn "\$(realpath ${keep_file})" "${target_dir}/${target_prefix}.keep"

    ln -sfn "${target_dir}/${target_prefix}.grm.bin" "synced_${target_prefix}.grm.bin"
    ln -sfn "${target_dir}/${target_prefix}.grm.id" "synced_${target_prefix}.grm.id"
    ln -sfn "${target_dir}/${target_prefix}.grm.details" "synced_${target_prefix}.grm.details"
    ln -sfn "${target_dir}/${target_prefix}.grm.adjust" "synced_${target_prefix}.grm.adjust"
    ln -sfn "${target_dir}/${target_prefix}.keep" "synced_${target_prefix}.keep"

    echo "linked ${target_dir}/${target_prefix}" > "${target_prefix}.linked"
    """
}
