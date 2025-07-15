process CALC_KINS_META {
    tag "calc_kins_meta"
    publishDir "${params.pubDir}/ldak", mode: 'copy'


    input:
    path imputed_plink_ch   // Channel with imputed PLINK files (bed, bim, fam)
    val heritability_model  // Heritability model parameter (optional)

    output:
    path "meta_grm.grm.bin", emit: grm_bin
    path "meta_grm.grm.id", emit: grm_id
    path "meta_grm.grm.details", emit: grm_details
    path "meta_grm.grm.adjust", emit: grm_adjust
    tuple path("meta_grm.grm.bin"), path("meta_grm.grm.id"), path("meta_grm.grm.details"), path("meta_grm.grm.adjust"), emit: meta_grm

    script:
    def heritability_model_param = heritability_model ? "--her-model ${heritability_model}" : ''
    
    """
    # Run LDAK to calculate meta kinship matrix
    ldak6 --calc-kins-direct meta_grm --bfile meta_grm --power -.25 ${heritability_model_param} --max-threads ${task.cpus}
    """
}
