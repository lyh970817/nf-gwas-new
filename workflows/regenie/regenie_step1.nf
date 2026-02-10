include { REGENIE_STEP1_RUN           } from '../../modules/local/regenie/regenie_step1_run'
include { REGENIE_STEP1_SPLIT         } from '../../modules/local/regenie/regenie_step1_split'
include { REGENIE_STEP1_MERGE_CHUNKS  } from '../../modules/local/regenie/regenie_step1_merge_chunks'
include { REGENIE_STEP1_RUN_CHUNK     } from '../../modules/local/regenie/regenie_step1_run_chunk'

workflow REGENIE_STEP1 {

    take:
    genotyped_final_ch
    phenotype_meta_ch
    covariates_file_validated

    main:
    step1_inputs = genotyped_final_ch
        .combine(phenotype_meta_ch)
        .map { genotyped_name, genotyped_files, phenotype_name, phenotypes_file, is_binary ->
            tuple(genotyped_name, genotyped_files, phenotypes_file, covariates_file_validated, phenotype_name, is_binary)
        }

    if (params.genotypes_prediction_chunks > 0){

        REGENIE_STEP1_SPLIT (
            step1_inputs
        )

        Channel.of(1..params.genotypes_prediction_chunks)
            .combine(REGENIE_STEP1_SPLIT.out.chunks)
            .set { chunks_ch }

        REGENIE_STEP1_RUN_CHUNK (
            chunks_ch
        )

        chunk_outputs_by_pheno = REGENIE_STEP1_RUN_CHUNK.out.regenie_step1_out
            .groupTuple()
            .map { phenotype_name, files -> tuple(phenotype_name, files.flatten()) }

        split_context_ch = REGENIE_STEP1_SPLIT.out.chunks
            .map { master, _snplist, genotyped_plink_filename, genotyped_plink_file, phenotypes_file, covariates_file, phenotype_name, is_binary ->
                tuple(phenotype_name, master, genotyped_plink_filename, genotyped_plink_file, phenotypes_file, covariates_file, is_binary)
            }
            .groupTuple()
            .map { phenotype_name, masters, genotyped_names, genotyped_files, phenotypes_files, covariates_files, is_binary_values ->
                tuple(phenotype_name, masters[0], genotyped_names[0], genotyped_files[0], phenotypes_files[0], covariates_files[0], is_binary_values[0])
            }

        merge_inputs = split_context_ch
            .join(chunk_outputs_by_pheno, by: 0)
            .map { phenotype_name, master, genotyped_name, genotyped_file, phenotypes_file, covariates_file, is_binary, chunk_files ->
                tuple(master, genotyped_name, genotyped_file, chunk_files, phenotypes_file, covariates_file, phenotype_name, is_binary)
            }

        REGENIE_STEP1_MERGE_CHUNKS (
            merge_inputs
        )

        regenie_step1_out_ch = REGENIE_STEP1_MERGE_CHUNKS.out.regenie_step1_out
            .concat(REGENIE_STEP1_MERGE_CHUNKS.out.regenie_step1_out_pred)

    } else {
        REGENIE_STEP1_RUN (
            step1_inputs
        )

        regenie_step1_out_ch = REGENIE_STEP1_RUN.out.regenie_step1_out
    }
    emit:
    regenie_step1_out_ch
}
