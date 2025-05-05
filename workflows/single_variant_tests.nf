include { REGENIE              } from './regenie/regenie'


workflow SINGLE_VARIANT_TESTS {

    take:
    imputed_plink2_ch
    phenotypes_file
    covariates_file
    genotyped_plink_ch
    association_build
    genotypes_association_format
    condition_list_file
    skip_predictions

    main:

    genotyped_final_ch = Channel.empty()

    if (!skip_predictions) {

        genotyped_final_ch = genotyped_plink_ch

    }

    REGENIE (
        genotyped_final_ch,
        phenotypes_file,
        covariates_file,
        condition_list_file.collect().ifEmpty([]),
        imputed_plink2_ch,
        genotypes_association_format,
        skip_predictions
    )

    // regenie_step2_out = REGENIE.out.regenie_step2_out
    // regenie_step1_out_ch = REGENIE.out.regenie_step1_out_ch

}

