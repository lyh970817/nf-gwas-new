process SYNC_SUMSTATS_LINKS {
    tag "sync_sumstats_${trait_name}_${method_name}"
    publishDir "${params.pubDir}/summary_stats_links", mode: 'copy', pattern: '*.linked'
    label 'process_low'

    input:
    tuple val(trait_name), val(method_name), path(sumstats_file)
    val(summary_stats_dir)

    output:
    tuple val(trait_name), path("*.linked"), emit: linked_marker
    tuple val(trait_name), path("*.sumstats"), emit: linked_sumstats

    script:
    def safe_trait = trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')
    def safe_method = method_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')
    def target_name = "${safe_trait}.${safe_method}.sumstats"

    """
    mkdir -p "${summary_stats_dir}"

    if [[ -e "${summary_stats_dir}/${target_name}" || -L "${summary_stats_dir}/${target_name}" ]]; then
        rm -f "${summary_stats_dir}/${target_name}"
    fi

    ln -s "\$(realpath ${sumstats_file})" "${summary_stats_dir}/${target_name}"

    ln -s "${summary_stats_dir}/${target_name}" "${target_name}"
    echo "linked ${summary_stats_dir}/${target_name}" > "${safe_trait}.linked"
    """
}
