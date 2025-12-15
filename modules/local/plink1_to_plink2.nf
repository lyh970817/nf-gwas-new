// Convert PLINK1 format (bed/bim/fam) to PLINK2 format (pgen/psam/pvar)
process PLINK1_TO_PLINK2 {

    input:
    tuple val(chr_num), val(basename), path(bed), path(bim), path(fam), val(range)

    output:
    tuple val(chr_num), val(basename), path("${basename}.pgen"), path("${basename}.psam"), path("${basename}.pvar"), val(range), emit: plink2

    script:
    """
    plink2 \\
        --bfile ${basename} \\
        --make-pgen \\
        --out ${basename} \\
        --threads ${task.cpus} \\
        --memory ${task.memory.toMega()}
    """
}
