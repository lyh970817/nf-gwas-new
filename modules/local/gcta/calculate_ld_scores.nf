process CALCULATE_LD_SCORES {
    tag "${filename}"
    publishDir "${params.pubDir}/gcta_ldms", mode: 'copy', pattern: "*_gcta_ld.score.ld"

    input:
    tuple val(filename), path(plink2_pgen_file), path(plink2_psam_file), path(plink2_pvar_file), val(range)

    output:
    tuple val(filename), path("${filename}_gcta_ld.score.ld"), emit: ld_scores
    tuple val(filename), path("${filename}_snp_group*.txt"), emit: snp_group_files

    script:
    """
    # Convert PLINK2 files to PLINK1 format for GCTA
    plink2 --pfile ${filename} --make-bed --out ${filename}

    # Calculate LD scores using GCTA
    gcta \\
        --bfile ${filename} \\
        --ld-score-region 200 \\
        --out ${filename}_gcta_ld \\
        --thread-num ${task.cpus}

    # Segment SNPs into groups based on LD scores
    Rscript ${projectDir}/bin/segment_snp.R ${filename}_gcta_ld.score.ld ${filename}
    """
}
