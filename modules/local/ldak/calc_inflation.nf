process CALC_INFLATION {
    tag "calc_inflation"
    publishDir "${params.pubDir}/ldak/inflation", mode: 'copy'

    input:
    path ldak_reml_file
    path quarter_reml_files

    output:
    path "inflation_results.txt", emit: inflation_results

    script:
    """
    calc_inflation.R ${ldak_reml_file} ${quarter_reml_files.join(' ')}
    """
}
