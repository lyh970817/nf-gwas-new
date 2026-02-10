/*
========================================================================================
    CALC_GENOTYPE_ERROR Workflow - Calculate genotype error using LDAK HE
========================================================================================
*/

include { CALC_KINS } from './calc_kins'
include { MAKE_MGRM_LDAK } from '../../modules/local/ldak/make_mgrm_ldak'
include { ADD_GRMS } from '../../modules/local/ldak/add_grms'
include { FILTER_RELATEDNESS } from '../../modules/local/ldak/filter_relatedness'
include { LDAK_HE } from '../../modules/local/ldak/ldak_he'
include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { CALC_GENOTYPE_ERROR_T2 } from '../../modules/local/ldak/calc_genotype_error_t2'

workflow CALC_GENOTYPE_ERROR {
    take:
    imputed_plink_ch   // Channel with imputed PLINK files (bed, bim, fam)
    phenotype_meta_ch  // Channel: tuple(phenotype_name, phenotype_file, is_binary)
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
        phenotype_meta_ch.map { phenotype_name, phenotypes_file, _is_binary -> tuple(phenotype_name, phenotypes_file) },
        covariates_file
    )

    // Get the covariates files or use empty channel if not available
    def quant_covariates = PREPARE_PHENOCOV.out.covariates_quant_noheader
        .toList()
        .map { files -> files ? files[0] : [] }
    def cat_covariates = PREPARE_PHENOCOV.out.covariates_cat_noheader
        .toList()
        .map { files -> files ? files[0] : [] }

    // Extract batch subset parameters from the tuple
    def batch_subset_prefix = batch_subsets[0]
    def batch_subset_number = batch_subsets[1]

    // Run LDAK HE analysis with batch subset parameters
    he_pairs = ADD_GRMS.out.combined_grm
        .map { grm_name, bin, id, details, adjust -> [grm_name, bin, id, details, adjust, []] }
        .combine(PREPARE_PHENOCOV.out.phenotypes_noheader)

    he_grm = he_pairs.map { grm_name, grm_bin, grm_id, grm_details, grm_adjust, grm_root, _phenotype_name, _phenotype_file ->
        tuple(grm_name, grm_bin, grm_id, grm_details, grm_adjust, grm_root)
    }
    he_pheno = he_pairs.map { _grm_name, _grm_bin, _grm_id, _grm_details, _grm_adjust, _grm_root, phenotype_name, phenotype_file ->
        tuple(phenotype_name, phenotype_file)
    }

    LDAK_HE(
        he_grm,
        FILTER_RELATEDNESS.out.filtered_list,
        he_pheno,
        quant_covariates,
        cat_covariates,
        batch_subset_prefix,
        batch_subset_number
    )

    // Calculate T2 statistic from HE results
    CALC_GENOTYPE_ERROR_T2(
        LDAK_HE.out.he_results
    )

    emit:
    ldak_grm = CALC_KINS.out.ldak_grm
    mgrm_file = MAKE_MGRM_LDAK.out.mgrm_file
    combined_grm = ADD_GRMS.out.combined_grm
    filtered_list = FILTER_RELATEDNESS.out.filtered_list
    he_results = LDAK_HE.out.he_results
    genotype_error_results = CALC_GENOTYPE_ERROR_T2.out.genotype_error_results
}
