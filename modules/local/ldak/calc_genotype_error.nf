/*
========================================================================================
    CALC_GENOTYPE_ERROR Workflow - Calculate genotype error using LDAK HE
========================================================================================
*/

include { CALC_KINS } from '../../../workflows/ldak/calc_kins'
include { MAKE_MGRM_LDAK } from './make_mgrm_ldak'
include { ADD_GRMS } from './add_grms'
include { FILTER_RELATEDNESS } from './filter_relatedness'
include { LDAK_HE } from './ldak_he'
include { PREPARE_PHENOCOV } from '../gcta/prepare_phenocov'

workflow CALC_GENOTYPE_ERROR {
    take:
    imputed_plink_ch   // Channel with imputed PLINK files (bed, bim, fam)
    phenotype_file     // Path to phenotype file
    covariates_file    // Path to covariates file (optional)
    batch_subsets      // Tuple: [batch_subset_prefix, batch_subset_number, list_of_paths]

    main:
    // Run LDAK to calculate kinship matrix
    CALC_KINS(
        imputed_plink_ch,
        "human_default"
    )

    // Extract GRM prefixes from CALC_KINS output
    grm_prefixes = CALC_KINS.out.ldak_grm
        .map { _chr_num, filename, _bin_file, _id_file, _details_file, _adjust_file ->
            filename
        }
        .collect()

    // Create MGRM file containing all GRM root names
    MAKE_MGRM_LDAK(
        grm_prefixes,
        "batch_grm"
    )

    // Collect all GRM files for use in ADD_GRMS
    grm_files = CALC_KINS.out.ldak_grm
        .map { _chr_num, _filename, bin_file, id_file, details_file, adjust_file ->
            [bin_file, id_file, details_file, adjust_file]
        }
        .flatten()
        .collect()

    // Combine all GRMs using the MGRM file
    ADD_GRMS(
        MAKE_MGRM_LDAK.out.mgrm_file,
        grm_files,
        "batch_grm"
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

    // Extract batch subset parameters from the tuple
    def batch_subset_prefix = batch_subsets[0]
    def batch_subset_number = batch_subsets[1]

    // Run LDAK HE analysis with batch subset parameters
    LDAK_HE(
        ADD_GRMS.out.combined_grm,
        FILTER_RELATEDNESS.out.filtered_list,
        PREPARE_PHENOCOV.out.phenotypes_noheader,
        quant_covariates,
        cat_covariates,
        batch_subset_prefix,
        batch_subset_number
    )

    emit:
    ldak_grm = CALC_KINS.out.ldak_grm
    mgrm_file = MAKE_MGRM_LDAK.out.mgrm_file
    combined_grm = ADD_GRMS.out.combined_grm
    filtered_list = FILTER_RELATEDNESS.out.filtered_list
    he_results = LDAK_HE.out.he_results
}
