process CALCULATE_LD_SCORES {
  tag "${filename}"
  publishDir "${params.pubDir}/gcta_ldms", mode: 'copy', pattern: "*_gcta_ld.score.ld"

  input:
  tuple val(chr_num), val(filename), path(plink_bed_file), path(plink_fam_file), path(plink_bim_file), val(range)

  output:
  tuple val(filename), path("${filename}_gcta_ld.score.ld"), emit: ld_scores
  tuple val(filename), path("${filename}_snp_group*.txt"), emit: snp_group_files

  script:
  """
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
