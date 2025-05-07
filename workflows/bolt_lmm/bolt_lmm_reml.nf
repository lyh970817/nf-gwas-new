/*
========================================================================================
    BOLT-LMM REML Workflow
========================================================================================
*/

include { PREPARE_PHENOCOV } from '../../modules/local/gcta/prepare_phenocov'
include { RUN_BOLT_REML } from '../../modules/local/bolt_lmm/run_reml'
include { IMPUTED_TO_PLINK } from '../../modules/local/imputed_to_plink'

workflow BOLT_LMM_REML {
    take:
    imputed_plink_ch   // Channel with imputed PLINK2 files (tuple with [prefix, pgen_files, psam_files, pvar_files])
    phenotypes_file     // Path to phenotypes file
    covariates_file     // Path to covariates file (optional)

    main:
    // Prepare phenotypes and covariates files (remove headers and split covariates)

    // Convert VCF files to PLINK1 format using the IMPUTED_TO_PLINK process
    bed_plink_files = imputed_plink_ch
        .map { _filename, bed, _bim, _fam, _range ->
            bed
        }
        .collect()

    bim_plink_files = imputed_plink_ch
        .map { _filename, _bed, bim, _fam, _range ->
            bim
        }
        .collect()

    fam_plink_file = imputed_plink_ch
        .map { _filename, _bed, _bim, fam, _range ->
            fam
        }
        .first()

    // Run BOLT-LMM REML analysis with PLINK1 format files
    RUN_BOLT_REML(
        bed_plink_files,
        bim_plink_files,
        fam_plink_file,
        phenotypes_file,
        covariates_file
    )

    // emit:
    // reml_results = RUN_BOLT_REML.out.reml_results
    // log_file = RUN_BOLT_REML.out.log_file
}
