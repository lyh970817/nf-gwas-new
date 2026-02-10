process LDSC_H2 {
    tag "ldsc_h2_${trait_name}"
    publishDir "${params.pubDir}/ldsc/h2", mode: 'copy'
    label 'process_low'

    input:
    tuple val(trait_name), path(sumstats)
    val ref_ld_chr
    val w_ld_chr

    output:
    path "${trait_name}.h2.tsv", emit: heritability_results
    path "${trait_name}.log", emit: h2_log

    script:
    def extra_args = params.ldsc_h2_extra_args ?: ''

    """
    LDSC_BIN="ldsc.py"
    if [[ -x ./ldsc.py ]]; then
        LDSC_BIN="./ldsc.py"
    fi

    if command -v "\${LDSC_BIN}" >/dev/null 2>&1 || [[ -x "\${LDSC_BIN}" ]]; then
        "\${LDSC_BIN}" \\
            --h2 ${sumstats} \\
            --ref-ld-chr ${ref_ld_chr} \\
            --w-ld-chr ${w_ld_chr} \\
            --out ${trait_name} \\
            ${extra_args}
    else
        echo "ERROR: ldsc.py not found in PATH" >&2
        exit 127
    fi

    awk -v trait="${trait_name}" '
    BEGIN {
        OFS = "\t"
        estimate = "NA"
        se = "NA"
    }
    /Total Observed scale h2/ {
        line = \$0
        sub(/^.*: */, "", line)
        gsub(/[()]/, "", line)
        split(line, parts, /[[:space:]]+/)
        if (length(parts[1]) > 0) estimate = parts[1]
        if (length(parts[2]) > 0) se = parts[2]
        exit
    }
    END {
        print "trait", "h2", "se"
        print trait, estimate, se
    }
    ' ${trait_name}.log > ${trait_name}.h2.tsv
    """

    stub:
    """
    cat <<EOF > ${trait_name}.log
Total Observed scale h2: 0.2100 (0.0300)
EOF

    cat <<EOF > ${trait_name}.h2.tsv
trait	h2	se
${trait_name}	0.2100	0.0300
EOF
    """
}
