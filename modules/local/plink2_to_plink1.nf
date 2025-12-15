// Convert PLINK2 format (pgen/psam/pvar) to PLINK1 format (bed/bim/fam)
process PLINK2_TO_PLINK1 {

    input:
    tuple val(chr_num), val(basename), path(pgen), path(psam), path(pvar), val(range)

    output:
    tuple val(chr_num), val(basename), path("${basename}.bed"), path("${basename}.bim"), path("${basename}.fam"), val(range), emit: plink1

    script:
    """
    plink2 \\
        --pfile ${basename} \\
        --make-bed \\
        --out ${basename} \\
        --threads ${task.cpus} \\
        --memory ${task.memory.toMega()}
    """
}
