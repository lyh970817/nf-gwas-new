include { REGENIE              } from './regenie/regenie'


workflow SINGLE_VARIANT_TESTS {

    take:
    imputed_plink1_ch
    phenotype_meta_ch
    covariates_file
    genotyped_plink_ch
    association_build
    genotypes_association_format
    skip_predictions

    main:

    genotyped_final_ch = Channel.empty()

    if (!skip_predictions) {

        genotyped_final_ch = genotyped_plink_ch

    }

    REGENIE (
        genotyped_final_ch,
        phenotype_meta_ch,
        covariates_file,
        imputed_plink1_ch,
        genotypes_association_format,
        skip_predictions
    )

    emit:
    regenie_step2_results = REGENIE.out.regenie_step2_out
    regenie_step1_results = REGENIE.out.regenie_step1_out_ch
    merged_results = REGENIE.out.merged_results
    munged_sumstats = REGENIE.out.munged_sumstats

}
