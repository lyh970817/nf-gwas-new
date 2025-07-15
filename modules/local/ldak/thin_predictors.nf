process THIN_PREDICTORS {
    tag "${filename}"
    publishDir "${params.pubDir}/ldak", mode: 'copy'

    input:
    tuple val(chr_num), val(filename), path(plink_bed_file), path(plink_bim_file), path(plink_fam_file), val(range)

    output:
    path "thin_${filename}.in", emit: thin_predictors

    script:
    """
    # Run LDAK thinning to select predictors
    ldak6 --thin thin_${filename} --bfile ${filename} --window-prune 0.98 --window-kb 100 --max-threads ${task.cpus}
    """
}
