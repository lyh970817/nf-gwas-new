include { REGENIE_STEP1 } from './regenie_step1'
include { REGENIE_STEP2 } from './regenie_step2'

workflow REGENIE {
    take:
    genotyped_final_ch
    phenotype_meta_ch
    covariates_file_validated
    imputed_plink1_ch
    genotypes_association_format
    skip_predictions

    main:
    regenie_step1_out_ch = Channel.empty()
    REGENIE_STEP1(
        genotyped_final_ch,
        phenotype_meta_ch,
        covariates_file_validated
    )

    regenie_step1_out_ch = REGENIE_STEP1.out.regenie_step1_out_ch

    REGENIE_STEP2(
        regenie_step1_out_ch,
        imputed_plink1_ch,
        genotypes_association_format,
        phenotype_meta_ch,
        covariates_file_validated
    )

    regenie_step2_out = REGENIE_STEP2.out.regenie_step2_out
    merged_results = REGENIE_STEP2.out.merged_results
    munged_sumstats = REGENIE_STEP2.out.munged_sumstats

    emit:
    regenie_step1_out_ch
    regenie_step2_out
    merged_results
    munged_sumstats
}
