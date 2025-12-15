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
    # IDs are the same across all partitions - use the first one
    cp gcta_grm_${suffix}.part_${nparts_gcta}_1.grm.id ${prefix}.grm.id

    # Concatenate all binary files in order
    for i in \$(seq 1 ${nparts_gcta}); do
        cat gcta_grm_${suffix}.part_${nparts_gcta}_\${i}.grm.bin
    done > ${prefix}.grm.bin

    # Concatenate all N.bin files in order
    for i in \$(seq 1 ${nparts_gcta}); do
        cat gcta_grm_${suffix}.part_${nparts_gcta}_\${i}.grm.N.bin
    done > ${prefix}.grm.N.bin
    """
}
