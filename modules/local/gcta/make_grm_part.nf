process MAKE_GRM_PART {
    tag "part ${part_gcta_job} of ${nparts_gcta}"

    input:
    path mpfile
    tuple val(part_gcta_job), val(nparts_gcta), val(snp_group), path(snp_group_file)
    path plink2_files

    output:
    tuple val(nparts_gcta),
          val(snp_group),
          path("gcta_grm_${snp_group}.part_${nparts_gcta}_${part_gcta_job}.grm.id"),
          path("gcta_grm_${snp_group}.part_${nparts_gcta}_${part_gcta_job}.grm.bin"),
          path("gcta_grm_${snp_group}.part_${nparts_gcta}_${part_gcta_job}.grm.N.bin"), emit: grm_files

    script:
    def suffix = snp_group ? "${snp_group}" : "0"
    def out = "gcta_grm_${suffix}"
    def extract_cmd = snp_group_file ? "--extract ${snp_group_file}" : ""
    """
    gcta --mpfile ${mpfile} --make-grm-part ${nparts_gcta} ${part_gcta_job} ${extract_cmd} --maf 0.01 --thread-num ${task.cpus} --out ${out}
    """
}
