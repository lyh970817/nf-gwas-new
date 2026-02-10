process LDSC_RG {
    tag "ldsc_rg_${trait1_name}_${trait2_name}"
    publishDir "${params.pubDir}/ldsc/rg", mode: 'copy'
    label 'process_low'

    input:
    tuple val(trait1_name), path(sumstats1), val(trait2_name), path(sumstats2)
    val ref_ld_chr
    val w_ld_chr

    output:
    path "${trait1_name}.${trait2_name}.rg.tsv", emit: correlation_results
    path "${trait1_name}.${trait2_name}.log", emit: rg_log

    script:
    def extra_args = params.ldsc_rg_extra_args ?: ''

    """
    LDSC_BIN="ldsc.py"
    if [[ -x ./ldsc.py ]]; then
        LDSC_BIN="./ldsc.py"
    fi

    if command -v "\${LDSC_BIN}" >/dev/null 2>&1 || [[ -x "\${LDSC_BIN}" ]]; then
        "\${LDSC_BIN}" \\
            --rg ${sumstats1},${sumstats2} \\
            --ref-ld-chr ${ref_ld_chr} \\
            --w-ld-chr ${w_ld_chr} \\
            --out ${trait1_name}.${trait2_name} \\
            ${extra_args}
    else
        echo "ERROR: ldsc.py not found in PATH" >&2
        exit 127
    fi

    awk -v trait1="${trait1_name}" -v trait2="${trait2_name}" '
    BEGIN {
        OFS = "\t"
        rg = "NA"
        se = "NA"
    }
    /^p1[[:space:]]+p2[[:space:]]+rg[[:space:]]+se/ {
        if (getline > 0) {
            if (NF >= 4) {
                rg = \$3
                se = \$4
            }
        }
    }
    END {
        print "trait1", "trait2", "rg", "se"
        print trait1, trait2, rg, se
    }
    ' ${trait1_name}.${trait2_name}.log > ${trait1_name}.${trait2_name}.rg.tsv
    """

    stub:
    """
    cat <<EOF > ${trait1_name}.${trait2_name}.log
p1 p2 rg se z p
${trait1_name} ${trait2_name} 0.3500 0.0700 5.0000 0.000001
EOF

    cat <<EOF > ${trait1_name}.${trait2_name}.rg.tsv
trait1	trait2	rg	se
${trait1_name}	${trait2_name}	0.3500	0.0700
EOF
    """
}
