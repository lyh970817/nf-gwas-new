/*
========================================================================================
    CALC_KINS Workflow - Conditional kinship calculation based on heritability model
========================================================================================
*/

include { CALC_KINS_HUMAN } from '../../modules/local/ldak/calc_kins_human'
include { CALC_KINS_UNIFORM } from '../../modules/local/ldak/calc_kins_uniform'
include { CALC_KINS_WEIGHTS } from '../../modules/local/ldak/calc_kins_weights'
include { THIN_PREDICTORS } from '../../modules/local/ldak/thin_predictors'
include { CREATE_THIN_WEIGHTS } from '../../modules/local/ldak/create_thin_weights'

workflow CALC_KINS {
    take:
    imputed_plink_ch   // Channel with imputed PLINK files (bed, bim, fam)
    heritability_model // Heritability model parameter (optional)

    main:
    if (heritability_model == 'human_default') {
        // Use human default kinship calculation
        CALC_KINS_HUMAN(imputed_plink_ch)
        ldak_grm = CALC_KINS_HUMAN.out.ldak_grm
        
    } else if (heritability_model == 'uniform') {
        // Use uniform weighting kinship calculation
        CALC_KINS_UNIFORM(imputed_plink_ch)
        ldak_grm = CALC_KINS_UNIFORM.out.ldak_grm
        
    } else if (heritability_model == 'ldak-thin') {
        // Use LDAK thinning approach
        THIN_PREDICTORS(imputed_plink_ch)

        // Create weights file from thin predictors
        CREATE_THIN_WEIGHTS(THIN_PREDICTORS.out.thin_predictors)
        
        // Calculate kinship using weights
        CALC_KINS_WEIGHTS(
            imputed_plink_ch,
            CREATE_THIN_WEIGHTS.out.thin_weights
        )
        ldak_grm = CALC_KINS_WEIGHTS.out.ldak_grm
        
    } else {
        // Default to human_default if heritability_model is null or unrecognized
        CALC_KINS_HUMAN(imputed_plink_ch)
        ldak_grm = CALC_KINS_HUMAN.out.ldak_grm
    }

    emit:
    ldak_grm
}
