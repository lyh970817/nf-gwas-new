process CALC_KINS {
    tag "${filename}"
    publishDir "${params.pubDir}/ldak", mode: 'copy'

    // Use container or conda environment with LDAK installed
    // Uncomment and modify one of these lines based on your setup:
    // container 'quay.io/biocontainers/ldak:5.2--h516909a_0'  // Example container
    // conda 'bioconda::ldak=5.2'                             // Example conda package

    input:
    tuple val(filename), path(plink_bed_file), path(plink_bim_file), path(plink_fam_file), val(range)

    output:
    tuple val(filename), path("${filename}.grm.bin"), path("${filename}.grm.id"), path("${filename}.grm.details"), path("${filename}.grm.adjust"), emit: ldak_grm

    script:
    """
    # Run LDAK
    ldak6 --calc-kins-direct ${filename} --bfile ${filename} --power -.25 --max-threads ${task.cpus}
    """
}
