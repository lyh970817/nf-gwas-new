/*
========================================================================================
    LDSC Munge Summary Statistics Process
========================================================================================
    Converts raw GWAS summary statistics into LDSC-compatible .sumstats.gz files
    using munge_sumstats.py.
========================================================================================
*/

process LDSC_MUNGE_SUMSTATS {
    tag "ldsc_munge_${trait_name}"
    publishDir "${params.pubDir}/ldsc/munged", mode: 'copy'
    label 'process_low'

    input:
    tuple val(trait_name), path(summary_stats)

    output:
    tuple val(trait_name), path("${trait_name}.sumstats.gz"), emit: munged_sumstats
    path "${trait_name}.log", emit: munge_log

    script:
    def snp_col = params.sumstats_snp_col ?: 'Predictor'
    def a1_col = params.sumstats_a1_col ?: 'A1'
    def a2_col = params.sumstats_a2_col ?: 'A2'
    def n_col = params.sumstats_n_col ?: 'n'
    def signed_sumstats = params.ldsc_munge_signed_sumstats ? "--signed-sumstats ${params.ldsc_munge_signed_sumstats}" : ''
    def extra_args = params.ldsc_munge_extra_args ?: ''

    """
    MUNGE_BIN="munge_sumstats.py"
    if [[ -x ./munge_sumstats.py ]]; then
        MUNGE_BIN="./munge_sumstats.py"
    fi

    if command -v "\${MUNGE_BIN}" >/dev/null 2>&1 || [[ -x "\${MUNGE_BIN}" ]]; then
        "\${MUNGE_BIN}" \\
            --sumstats ${summary_stats} \\
            --out ${trait_name} \\
            --snp ${snp_col} \\
            --a1 ${a1_col} \\
            --a2 ${a2_col} \\
            --N-col ${n_col} \\
            ${signed_sumstats} \\
            ${extra_args}
    else
        echo "ERROR: munge_sumstats.py not found in PATH" >&2
        exit 127
    fi
    """

    stub:
    """
    cat ${summary_stats} | gzip -c > ${trait_name}.sumstats.gz
    cat <<EOF > ${trait_name}.log
    Stub munge_sumstats run for ${trait_name}
    Input file: ${summary_stats}
    EOF
    """
}
