process CALC_KINS_UNIFORM {
    tag "${filename}"
    publishDir "${params.pubDir}/ldak", mode: 'copy'

    input:
    tuple val(chr_num), val(filename), path(plink_bed_file), path(plink_bim_file), path(plink_fam_file), val(range)

    output:
    tuple val(chr_num), val(filename), path("${filename}.grm.bin"), path("${filename}.grm.id"), path("${filename}.grm.details"), path("${filename}.grm.adjust"), emit: ldak_grm

    script:
    """
    # Run LDAK with uniform weighting (power -1)
    ldak6 --calc-kins-direct ${filename} --bfile ${filename} --power -1 --ignore-weights YES --max-threads ${task.cpus}
    """
}
