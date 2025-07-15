process CREATE_THIN_WEIGHTS {
    tag "create_thin_weights"
    publishDir "${params.pubDir}/ldak", mode: 'copy'

    input:
    path thin_predictors_file

    output:
    path "weights.thin", emit: thin_weights

    script:
    """
    # Create weights file from thin predictors
    awk < ${thin_predictors_file} '{print \$1, 1}' > weights.thin
    """
}
