include { REGENIE_STEP2_RUN        } from '../../modules/local/regenie/regenie_step2_run'

workflow REGENIE_STEP2 {

    take:
    regenie_step1_out_ch
    imputed_plink2_ch
    genotypes_association_format
    phenotypes_file
    covariates_file_validated
    condition_list_file

    main:
    if (!params.regenie_sample_file) {
        sample_file = []
    } else {
        sample_file = file(params.regenie_sample_file, checkIfExists: true)
    }

    REGENIE_STEP2_RUN (
        regenie_step1_out_ch.collect(),
        imputed_plink2_ch,
        genotypes_association_format,
        phenotypes_file,
        sample_file,
        covariates_file_validated,
        condition_list_file
    )

    regenie_step2_out = REGENIE_STEP2_RUN.out.regenie_step2_out

    emit:
    regenie_step2_out

}