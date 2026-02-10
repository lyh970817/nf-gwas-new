process MERGE_GRM_PARTS {
  tag "merge ${nparts_gcta} parts"
  publishDir "${params.pubDir}/gcta", mode: 'copy', pattern: "gcta_grm.*"

  input:
  tuple val(nparts_gcta), val(snp_group), path(grm_ids), path(grm_bins), path(grm_n_bins)

  output:
  tuple val(snp_group), val(prefix), path("${prefix}.grm.id"), path("${prefix}.grm.bin"), path("${prefix}.grm.N.bin"), emit: grm_files

  script:
  def suffix = snp_group ? "${snp_group}" : "0"
  prefix = "gcta_grm_${suffix}"
  """
    # Calculate padding width (number of digits in nparts)
    NPARTS=${nparts_gcta}
    PAD_WIDTH=\${#NPARTS}

    # Concatenate all ID files in order (each partition has different individuals)
    # GCTA --make-grm-part divides individuals across partitions
    for i in \$(seq 1 ${nparts_gcta}); do
        PADDED=\$(printf "%0\${PAD_WIDTH}d" \$i)
        cat gcta_grm_${suffix}.part_${nparts_gcta}_\${PADDED}.grm.id
    done > ${prefix}.grm.id

    # Concatenate all binary files in order (with zero-padded part numbers)
    for i in \$(seq 1 ${nparts_gcta}); do
        PADDED=\$(printf "%0\${PAD_WIDTH}d" \$i)
        cat gcta_grm_${suffix}.part_${nparts_gcta}_\${PADDED}.grm.bin
    done > ${prefix}.grm.bin

    # Concatenate all N.bin files in order (with zero-padded part numbers)
    for i in \$(seq 1 ${nparts_gcta}); do
        PADDED=\$(printf "%0\${PAD_WIDTH}d" \$i)
        cat gcta_grm_${suffix}.part_${nparts_gcta}_\${PADDED}.grm.N.bin
    done > ${prefix}.grm.N.bin
    """
}
