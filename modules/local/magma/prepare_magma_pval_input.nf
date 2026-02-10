process PREPARE_MAGMA_PVAL_INPUT {
    tag "prepare_magma_pval_${trait_name}"
    publishDir "${params.pubDir}/magma/sumstats", mode: 'copy'
    label 'process_low'

    input:
    tuple val(trait_name), path(summary_stats_file)

    output:
    tuple val(trait_name), path { "${trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.magma.pval" }, emit: magma_pval_input

    script:
    def trait_slug = trait_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')
    def log10p_col = params.sumstats_log10p_col ?: ''
    def target_p_col = params.sumstats_p_col ?: 'P'

    """
    if [[ -n "${log10p_col}" ]]; then
        zcat -f "${summary_stats_file}" | awk -v log10p_col="${log10p_col}" -v target_p_col="${target_p_col}" '
            BEGIN {
                FS = "[[:space:]]+"
                OFS = "\t"
                log10p_idx = 0
                p_idx = 0
            }
            NR == 1 {
                for (i = 1; i <= NF; i++) {
                    if (\$i == log10p_col) {
                        log10p_idx = i
                    }
                    if (\$i == target_p_col) {
                        p_idx = i
                    }
                }
                if (log10p_idx == 0) {
                    printf("ERROR: column %s not found in header\\n", log10p_col) > "/dev/stderr"
                    exit 1
                }
                if (p_idx == 0) {
                    print \$0, target_p_col
                    p_idx = NF + 1
                } else {
                    print \$0
                }
                next
            }
            {
                if (log10p_idx > NF || \$log10p_idx == "") {
                    next
                }

                p = 10 ^ (-\$log10p_idx)
                if (p == 0) {
                    p = 1e-300
                }

                if (p_idx > NF) {
                    print \$0, p
                } else {
                    \$p_idx = p
                    print \$0
                }
            }
        ' > "${trait_slug}.magma.pval"
    else
        zcat -f "${summary_stats_file}" > "${trait_slug}.magma.pval"
    fi
    """
}
