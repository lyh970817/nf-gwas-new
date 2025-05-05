process IMPUTED_TO_PLINK {

    input:
    path imputed_vcf_file
    
    output:
    tuple val("${imputed_vcf_file.baseName}"), path("${imputed_vcf_file.baseName}.bed"), path("${imputed_vcf_file.baseName}.bim"), path("${imputed_vcf_file.baseName}.fam"), val(-1), emit: imputed_plink

    script:
    def delimiter = params.vcf_conversion_split_id ? "--id-delim" : '--double-id'
    """
    plink2 \\
        --vcf $imputed_vcf_file dosage=DS \\
        --make-bed \\
        $delimiter \\
        --out ${imputed_vcf_file.baseName} \\
        --threads ${task.cpus} \\
        --memory ${task.memory.toMega()}
    """
}
