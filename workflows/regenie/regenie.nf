include { REGENIE_STEP1 } from './regenie_step1'
include { REGENIE_STEP2 } from './regenie_step2'

workflow REGENIE {
    take:
    genotyped_final_ch
    phenotypes_file
    covariates_file_validated
    condition_list_file
    imputed_plink2_ch
    genotypes_association_format
    skip_predictions

    main:
    regenie_step1_out_ch = Channel.empty()
    REGENIE_STEP1(
        genotyped_final_ch,
        phenotypes_file,
        covariates_file_validated,
        condition_list_file.collect().ifEmpty([]),
    )

    regenie_step1_out_ch = REGENIE_STEP1.out.regenie_step1_out_ch

    REGENIE_STEP2(
        regenie_step1_out_ch,
        imputed_plink2_ch,
        genotypes_association_format,
        phenotypes_file,
        covariates_file_validated,
        condition_list_file.collect().ifEmpty([]),
    )

    regenie_step2_out = REGENIE_STEP2.out.regenie_step2_out

    emit:
    regenie_step1_out_ch
    regenie_step2_out
}
