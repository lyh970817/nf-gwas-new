process IMPUTED_TO_PLINK2 {

    input:
    tuple val(chr_num), path(imputed_vcf_file)
    
    output:
    tuple val(chr_num), val("${imputed_vcf_file.simpleName}"), path("${imputed_vcf_file.simpleName}.pgen"), path("${imputed_vcf_file.simpleName}.psam"), path("${imputed_vcf_file.simpleName}.pvar"), val(-1), emit: imputed_plink2

    script:
    def imputed_vcf_prefix = imputed_vcf_file.simpleName
    """
    plink2 \
        --vcf $imputed_vcf_file dosage=DS \
        --make-pgen \
        --double-id \
        --out ${imputed_vcf_prefix} \
        --threads ${task.cpus} \
        --memory ${task.memory.toMega()}
    """
}
