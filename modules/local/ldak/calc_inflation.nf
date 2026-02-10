process CALC_INFLATION {
    tag "calc_inflation"
    publishDir "${params.pubDir}/ldak/inflation", mode: 'copy'

    input:
    tuple val(phenotype_name), path(ldak_reml_file), path(quarter_reml_files)

    output:
    tuple val(phenotype_name), path { "inflation_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.txt" }, emit: inflation_results

    script:
    """
    calc_inflation.R ${ldak_reml_file} ${quarter_reml_files.join(' ')}
    mv inflation_results.txt inflation_${phenotype_name.replaceAll(/[^A-Za-z0-9._-]+/, '_')}.txt
    """
}
