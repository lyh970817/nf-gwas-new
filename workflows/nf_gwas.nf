
include { IMPUTED_TO_PLINK2 } from '../modules/local/imputed_to_plink2'
include { IMPUTED_TO_PLINK } from '../modules/local/imputed_to_plink'
include { GCTA_GRM } from '../workflows/gcta/gcta_grm'
include { GCTA_GREML } from './gcta/gcta_greml'
include { GCTA_GREML_LDMS } from './gcta/gcta_greml_ldms'
include { GCTA_FASTGWA } from './gcta/gcta_fastgwa'
include { LDAK } from './ldak/ldak'
include { LDAK_QC } from './ldak/ldak_qc'
include { THIN_PREDICTORS } from '../modules/local/ldak/thin_predictors'

// include { BOLT_LMM } from './bolt_lmm/bolt_lmm'
include { BOLT_LMM_REML } from './bolt_lmm/bolt_lmm_reml'
include { SINGLE_VARIANT_TESTS } from './single_variant_tests'

workflow NF_GWAS {
    // pubDir is now defined in nextflow.config
    println "Output directory: ${params.pubDir}"

    def ANSI_RESET = "\u001B[0m"
    def ANSI_YELLOW = "\u001B[33m"

    def genotypes_association = params.genotypes_association
    if(params.genotypes_imputed){
        genotypes_association = params.genotypes_imputed
        println ANSI_YELLOW + "WARN: Option genotypes_imputed is deprecated. Please use genotypes_association instead." + ANSI_RESET
    }

    //check deprecated option
    def genotypes_association_format = params.genotypes_association_format
    if(params.genotypes_imputed_format){
        genotypes_association_format = params.genotypes_imputed_format
        println ANSI_YELLOW + "WARN: Option genotypes_imputed_format is deprecated. Please use genotypes_association_format instead." + ANSI_RESET
    }

    def genotypes_prediction = params.genotypes_prediction
    if(params.genotypes_array){
        genotypes_prediction = params.genotypes_array
        println ANSI_YELLOW +  "WARN: Option genotypes_array is deprecated. Please use genotypes_prediction instead." + ANSI_RESET
    }

    def association_build = params.association_build
    if(params.genotypes_build){
        association_build = params.genotypes_build
        println ANSI_YELLOW +  "WARN: Option genotypes_build is deprecated. Please use association_build instead." + ANSI_RESET
    }

    if(params.rsids_filename == null) {
        println ANSI_YELLOW +   "WARN: A large rsID file will be downloaded for annotation. Please specify the path to the 'rsids_filename' parameter in the config (see docs for file creation) to avoid multiple downloads." + ANSI_RESET
    }

    // //validate input parameters
    // WorkflowMain.validate(params,genotypes_association_format)

    def skip_predictions = params.regenie_skip_predictions

    // Validate that all files contain double digit numbers and sort them
    imputed_files_ch = channel.fromPath(genotypes_association, checkIfExists: true)
        .toList()
        .flatMap { files ->
            // Check that all files contain double digit numbers
            def invalid_files = files.findAll { file ->
                !(file.name =~ /\d{2}/)
            }
            if (invalid_files) {
                error "Files without double digit numbers found: ${invalid_files.collect { it.name }.join(', ')}"
            }

            // Sort files by name and attach sequential chromosome numbers
            return files.sort { it.name }
                .withIndex(1)
                .collect { file, index -> [index, file] }
        }

    phenotypes_file = file(params.phenotypes_filename, checkIfExists: true)

    covariates_file = []
    if(params.covariates_filename) {
        covariates_file = file(params.covariates_filename, checkIfExists: true)
    }

    genotyped_plink_ch = Channel.empty()
    if(!skip_predictions) {
        genotyped_plink_ch = Channel.fromFilePairs(genotypes_prediction, size: 3, checkIfExists: true)
    }

    //Optional condition-list file
    condition_list_file = Channel.empty()
    if (params.regenie_condition_list) {
            condition_list_file = Channel.fromPath(params.regenie_condition_list)
    }

    // Convert imputed VCF files to PLINK2 format
    // Only VCF format is supported
    IMPUTED_TO_PLINK2 (
        imputed_files_ch
    )

    IMPUTED_TO_PLINK (
        imputed_files_ch
    )


    imputed_plink2_ch = IMPUTED_TO_PLINK2.out.imputed_plink2
    imputed_plink_ch = IMPUTED_TO_PLINK.out.imputed_plink

    // // Run GCTA GREML workflow which includes GCTA GRM calculation and REML analysis
    GCTA_GREML_LDMS (
        phenotypes_file,
        covariates_file,
        imputed_plink2_ch,
        imputed_plink_ch,
        params.nparts_gcta
    )

    // LDAK (
    //     imputed_plink_ch,
    //     phenotypes_file,
    //     covariates_file,
    //     "human_default"
    // )

    // LDAK (
    //     imputed_plink_ch,
    //     phenotypes_file,
    //     covariates_file,
    //     "uniform"
    // )

    LDAK (
        imputed_plink_ch,
        phenotypes_file,
        covariates_file,
        "ldak-thin"
    )

    // Run LDAK QC workflow for inflation testing
    // LDAK_QC (
    //     imputed_plink_ch,
    //     phenotypes_file,
    //     covariates_file
    // )
    
    
    

    // Run GCTA FastGWA workflow for mixed linear model GWAS
    // GCTA_FASTGWA (
    //     imputed_plink2_ch,
    //     phenotypes_file,
    //     covariates_file,
    //     params.nparts_gcta,
    //     params.sparse_cutoff
    // )

    // BOLT_LMM_REML (
    //     imputed_plink_ch,
    //     phenotypes_file,
    //     covariates_file,
    // )

    // SINGLE_VARIANT_TESTS(
    //     imputed_plink2_ch,
    //     phenotypes_file,
    //     covariates_file,
    //     genotyped_plink_ch,
    //     association_build,
    //     genotypes_association_format,
    //     condition_list_file,
    //     skip_predictions,
    // )

    // emit:
    // greml_results = GCTA_GREML.out.reml_results
    // fastgwa_results = GCTA_FASTGWA.out.fastgwa_results
    // ldms_results = GCTA_GREML_LDMS.out.reml_results
    // ld_scores = GCTA_GREML_LDMS.out.ld_scores
    // snp_groups = GCTA_GREML_LDMS.out.snp_groups
    // bolt_reml_results = BOLT_LMM.out.reml_results
    // bolt_log_file = BOLT_LMM.out.log_file
}

