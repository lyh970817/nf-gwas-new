/*
========================================================================================
    LDAK Workflow
========================================================================================
*/

include { CALC_KINS } from '../../modules/local/ldak/calc_kins'
include { MAKE_MGRM_LDAK } from '../../modules/local/ldak/make_mgrm_ldak'
include { ADD_GRMS } from '../../modules/local/ldak/add_grms'
include { FILTER_RELATEDNESS } from '../../modules/local/ldak/filter_relatedness'
include { LDAK_REML } from '../../modules/local/ldak/ldak_reml'
include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'

// Main workflow
workflow LDAK {
    take:
    imputed_plink_ch   // Channel with imputed PLINK files (bed, bim, fam)
    phenotype_file     // Path to phenotype file
    covariates_file    // Path to covariates file (optional)

    main:
    // Run LDAK to calculate kinship matrix
    CALC_KINS(
        imputed_plink_ch
    )

    // Extract GRM prefixes from CALC_KINS output
    grm_prefixes = CALC_KINS.out.ldak_grm
        .map { filename, _bin_file, _id_file, _details_file, _adjust_file ->
            filename
        }
        .collect()

    // Create MGRM file containing all GRM root names
    MAKE_MGRM_LDAK(
        grm_prefixes
    )

    // Collect all GRM files for use in ADD_GRMS
    grm_files = CALC_KINS.out.ldak_grm
        .map { _filename, bin_file, id_file, details_file, adjust_file ->
            [bin_file, id_file, details_file, adjust_file]
        }
        .flatten()
        .collect()

    // Combine all GRMs using the MGRM file
    ADD_GRMS(
        MAKE_MGRM_LDAK.out.mgrm_file,
        grm_files
    )

    // Filter related individuals from the combined GRM
    FILTER_RELATEDNESS(
        ADD_GRMS.out.combined_grm
    )

    // Prepare phenotypes and covariates files (remove headers and split covariates)
    PREPARE_PHENOCOV(
        phenotype_file,
        covariates_file
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .ifEmpty { Channel.of([]) }

    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .ifEmpty { Channel.of([]) }

    // Run LDAK REML analysis
    LDAK_REML(
        ADD_GRMS.out.combined_grm,
        FILTER_RELATEDNESS.out.filtered_list,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates
    )

    emit:
    ldak_grm = CALC_KINS.out.ldak_grm
    mgrm_file = MAKE_MGRM_LDAK.out.mgrm_file
    combined_grm = ADD_GRMS.out.combined_grm
    filtered_list = FILTER_RELATEDNESS.out.filtered_list
    reml_results = LDAK_REML.out.reml_results
}
