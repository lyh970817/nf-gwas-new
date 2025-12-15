process CALC_GENOTYPE_ERROR_T2 {
    tag "calc_genotype_error_t2"
    publishDir "${params.pubDir}/ldak/genotype_error", mode: 'copy'

    input:
    path he_results

    output:
    path "genotype_error_results.txt", emit: genotype_error_results

    script:
    """
    # Find the HE output files
    # LDAK HE with --subset-prefix and --subset-number produces:
    # - <prefix>.he (overall)
    # - <prefix>.he.within (same-batch)
    # - <prefix>.he.across (different-batch)

    overall_file=\$(ls *.he | grep -v '\\.within\$' | grep -v '\\.across\$' | head -n 1)
    within_file=\$(ls *.he.within | head -n 1)
    across_file=\$(ls *.he.across | head -n 1)

    if [ -z "\$overall_file" ] || [ -z "\$within_file" ] || [ -z "\$across_file" ]; then
        echo "Error: Missing required HE output files" >&2
        echo "Overall file: \$overall_file" >&2
        echo "Within file: \$within_file" >&2
        echo "Across file: \$across_file" >&2
        exit 1
    fi

    # Run the R script to calculate T2 statistic
    calc_genotype_error.R "\$overall_file" "\$within_file" "\$across_file"
    """
}
