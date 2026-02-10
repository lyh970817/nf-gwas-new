// =============================================================================
// DATA CONVERSION MODULES
// =============================================================================
include { IMPUTED_TO_PLINK2 } from '../modules/local/imputed_to_plink2'
include { IMPUTED_TO_PLINK } from '../modules/local/imputed_to_plink'
include { PLINK1_TO_PLINK2 } from '../modules/local/plink1_to_plink2'
include { PLINK2_TO_PLINK1 } from '../modules/local/plink2_to_plink1'
include { EXTRACT_PHENOTYPE_META } from '../modules/local/phenotypes/extract_phenotype_meta'

// =============================================================================
// 0. GRM-ONLY COMPUTATION WORKFLOWS
// =============================================================================
// GCTA GRM workflows
include { GCTA_GRM } from './gcta/gcta_grm'
include { GCTA_GRM_LDMS } from './gcta/gcta_grm_ldms'

// LDAK GRM workflow
include { LDAK_GRM } from './ldak/ldak_grm'

// =============================================================================
// 1. ASSOCIATION ANALYSIS WORKFLOWS
// =============================================================================
include { SINGLE_VARIANT_TESTS } from './single_variant_tests'
include { GCTA_FASTGWA } from './gcta/gcta_fastgwa'

// Analysis-only workflows (for pre-computed GRM)
include { GCTA_FASTGWA_ANALYSIS } from './gcta/gcta_fastgwa_analysis'

// =============================================================================
// 2. HERITABILITY ESTIMATION WORKFLOWS
// =============================================================================
// GCTA methods (standard workflows with auto-GRM computation)
include { GCTA_GREML } from './gcta/gcta_greml'
include { GCTA_GREML_LDMS } from './gcta/gcta_greml_ldms'

// GCTA analysis-only workflows (for pre-computed GRM)
include { GCTA_REML_ANALYSIS } from './gcta/gcta_reml_analysis'
include { GCTA_REML_LDMS_ANALYSIS } from './gcta/gcta_reml_ldms_analysis'

// BOLT-LMM methods
include { BOLT_LMM_REML } from './bolt_lmm/bolt_lmm_reml'

// LDAK methods (individual-level data - standard workflows with auto-GRM computation)
include { LDAK_REML_WORKFLOW } from './ldak/ldak_reml'
include { LDAK_HE_WORKFLOW } from './ldak/ldak_he'
include { LDAK_PCGC_WORKFLOW } from './ldak/ldak_pcgc'
include { LDAK_QC } from './ldak/ldak_qc'

// LDAK analysis-only workflows (for pre-computed GRM)
include { LDAK_REML_ANALYSIS } from './ldak/ldak_reml_analysis'
include { LDAK_HE_ANALYSIS } from './ldak/ldak_he_analysis'
include { LDAK_PCGC_ANALYSIS } from './ldak/ldak_pcgc_analysis'

// LDAK methods (summary statistics)
include { LDAK_SUMHER_WORKFLOW } from './ldak/ldak_sumher'
include { LDSC_H2_WORKFLOW     } from './ldsc/ldsc_h2'
include { LDAK_KVIK_WORKFLOW   } from './ldak/ldak_kvik'

// =============================================================================
// 3. GENETIC CORRELATION WORKFLOWS
// =============================================================================
include { LDAK_SUMCORS_WORKFLOW } from './ldak/ldak_sumcors'
include { LDSC_RG_WORKFLOW      } from './ldsc/ldsc_rg'
include { GCTA_BIVARIATE_GREML } from './gcta/gcta_bivariate_greml'
include { GCTA_BIVARIATE_GREML_LDMS } from './gcta/gcta_bivariate_greml_ldms'

// =============================================================================
// 4. GENE-BASED AND GENE-SET WORKFLOWS
// =============================================================================
include { MAGMA_GENE_BASED } from './magma/magma_gene_based'
include { MAGMA_GENE_BASED_RAW } from './magma/magma_gene_based_raw'
include { MAGMA_GENE_SET } from './magma/magma_gene_set'

// =============================================================================
// 5. OTHER WORKFLOWS
// =============================================================================
include { LAVA_LOCAL_RG } from './lava/lava_local_rg'
include { LCV_CAUSAL } from './lcv/lcv_causal'
include { SYNC_SUMSTATS_LINKS } from '../modules/local/sumstats/sync_sumstats_links'
include { SYNC_GCTA_GRM_LINKS } from '../modules/local/grm/sync_gcta_grm_links'
include { SYNC_GCTA_SPARSE_GRM_LINKS } from '../modules/local/grm/sync_gcta_sparse_grm_links'
include { SYNC_GCTA_GRM_LDMS_LINKS } from '../modules/local/grm/sync_gcta_grm_ldms_links'
include { SYNC_LDAK_GRM_LINKS } from '../modules/local/grm/sync_ldak_grm_links'

// =============================================================================
// MAIN WORKFLOW
// =============================================================================
workflow NF_GWAS {

  main:
  // =============================================================================
  // INITIALIZATION AND INPUT VALIDATION
  // =============================================================================
  def workflow_flags = [
    'run_assoc_regenie',
    'run_assoc_fastgwa',
    'run_assoc_kvik',
    'run_h2_gcta_grm',
    'run_h2_ldak_grm',
    'run_h2_gcta_greml',
    'run_h2_gcta_greml_ldms',
    'run_h2_bolt_lmm_reml',
    'run_h2_ldak_reml',
    'run_h2_ldak_he',
    'run_h2_ldak_pcgc',
    'run_h2_ldak_qc',
    'run_h2_ldak_sumher',
    'run_h2_ldsc_h2',
    'run_rg_ldak_sumcors',
    'run_rg_ldsc_rg',
    'run_rg_gcta_bivariate_greml',
    'run_rg_gcta_bivariate_greml_ldms',
    'run_magma_gene_based',
    'run_magma_gene_set',
    'run_lava_local_rg',
    'run_lcv_causal'
  ]

  if (!workflow_flags.any { params[it] == true }) {
    error("No workflows enabled. Enable at least one run_* workflow flag in nextflow.config or CLI.")
  }

  def removed_params = [
    'run_grm_only',
    'run_association_analysis',
    'run_gene_based_analysis',
    'run_gene_set_analysis',
    'run_heritability_estimation',
    'run_genetic_correlation',
    'grm_method',
    'association_method',
    'gene_based_method',
    'gene_set_method',
    'heritability_method',
    'genetic_correlation_method',
    'genotypes_prediction',
    'genotypes_association_vcf',
    'genotypes_association_plink1',
    'genotypes_association_plink2',
    'genotypes_imputed',
    'genotypes_association',
    'genotypes_array',
    'magma_raw_plink',
    'magma_use_regenie_merged',
    'magma_use_pipeline_gene_results',
    'magma_snp_col',
    'magma_p_col',
    'magma_log10p_col',
    'magma_n_col',
    'magma_n',
    'ldsc_h2_ref_ld_chr',
    'ldsc_h2_w_ld_chr',
    'ldsc_rg_ref_ld_chr',
    'ldsc_rg_w_ld_chr',
    'ldak_sumher_liftover',
    'ldak_sumher_target_build',
    'ldak_sumher_source_build',
    'ldak_sumher_frq_filter',
    'ldak_sumcors_liftover',
    'ldak_sumcors_target_build',
    'ldak_sumcors_source_build',
    'ldak_sumcors_frq_filter',
    'use_precomputed_grm'
  ]

  def supplied_removed = removed_params.findAll { params.containsKey(it) }
  if (!supplied_removed.isEmpty()) {
    error("Removed parameters detected: ${supplied_removed.join(', ')}. Use new workflow-flag and renamed parameter structure.")
  }

  println("Output directory: ${params.pubDir}")
  println("\n=== Analysis Configuration ===")
  println("Association: regenie=${params.run_assoc_regenie}, fastgwa=${params.run_assoc_fastgwa}, kvik=${params.run_assoc_kvik}")
  println("Heritability (individual): gcta_grm=${params.run_h2_gcta_grm}, ldak_grm=${params.run_h2_ldak_grm}, gcta_greml=${params.run_h2_gcta_greml}, gcta_greml_ldms=${params.run_h2_gcta_greml_ldms}, bolt=${params.run_h2_bolt_lmm_reml}, ldak_reml=${params.run_h2_ldak_reml}, ldak_he=${params.run_h2_ldak_he}, ldak_pcgc=${params.run_h2_ldak_pcgc}, ldak_qc=${params.run_h2_ldak_qc}")
  println("Heritability (sumstats): ldak_sumher=${params.run_h2_ldak_sumher}, ldsc_h2=${params.run_h2_ldsc_h2}")
  println("Genetic correlation: ldak_sumcors=${params.run_rg_ldak_sumcors}, ldsc_rg=${params.run_rg_ldsc_rg}, gcta_bivariate=${params.run_rg_gcta_bivariate_greml}, gcta_bivariate_ldms=${params.run_rg_gcta_bivariate_greml_ldms}")
  println("Gene based: magma_gene=${params.run_magma_gene_based}, magma_set=${params.run_magma_gene_set}")
  println("Other workflows: lava=${params.run_lava_local_rg}, lcv=${params.run_lcv_causal}")
  println("==============================\n")

  def ANSI_RESET = "\u001B[0m"
  def ANSI_YELLOW = "\u001B[33m"
  def ANSI_GREEN = "\u001B[32m"

  def parseTraitProportionFile = { mappingFile, contextLabel, valueLabel ->
    def traitValueMap = [:]

    if (mappingFile == null) {
      return traitValueMap
    }

    def mappingPath = file(mappingFile, checkIfExists: true)
    mappingPath.eachLine { rawLine, lineNum ->
      def line = rawLine?.trim()
      if (!line || line.startsWith('#')) {
        return
      }

      def tokens = line.split(/\s+/)
      if (tokens.size() < 2) {
        error("${contextLabel} ${valueLabel} mapping file ${mappingPath} has invalid format at line ${lineNum}: expected '<summary_stats_filename> <${valueLabel}>'")
      }

      def filenameKey = tokens[0]
      def mappedValue
      try {
        mappedValue = tokens[1] as BigDecimal
      } catch (Exception e) {
        error("${contextLabel} ${valueLabel} mapping file ${mappingPath} has invalid ${valueLabel} '${tokens[1]}' at line ${lineNum}")
      }

      if (mappedValue < 0 || mappedValue > 1) {
        error("${contextLabel} ${valueLabel} mapping file ${mappingPath} has out-of-range ${valueLabel} ${mappedValue} at line ${lineNum}; expected value between 0 and 1")
      }

      traitValueMap[filenameKey] = mappedValue.toString()
    }

    return traitValueMap
  }

  def imputed_genotyped_files_vcf = params.imputed_genotyped_files_vcf
  def genotyped_file = params.genotyped_file

  // REGENIE gene-based association has been removed from this pipeline
  def regenie_gene_based_params = [
    'regenie_gene_anno',
    'regenie_gene_setlist',
    'regenie_gene_masks',
    'regenie_gene_test',
    'regenie_gene_aaf',
    'regenie_gene_vc_max_aaf',
    'regenie_gene_vc_mac_thr',
    'regenie_gene_build_mask',
    'regenie_gene_joint'
  ]
  def provided_regenie_gene_based_params = regenie_gene_based_params.findAll { param_name -> params.containsKey(param_name) }
  def regenie_run_gene_based_tests = params.containsKey('regenie_run_gene_based_tests') ? params.get('regenie_run_gene_based_tests') : null
  def regenie_write_bed_masks = params.containsKey('regenie_write_bed_masks') ? params.get('regenie_write_bed_masks') : null
  if (regenie_run_gene_based_tests == true || regenie_write_bed_masks == true || !provided_regenie_gene_based_params.isEmpty()) {
    def provided_params_message = provided_regenie_gene_based_params.isEmpty() ? '' : " Provided parameters: ${provided_regenie_gene_based_params.join(', ')}."
    error("REGENIE gene-based association workflow has been removed from this pipeline. Please remove --regenie_run_gene_based_tests and all REGENIE gene-based parameters from your command.${provided_params_message}")
  }

  def regenie_gene_based_cli_flags = [
    '--anno-file',
    '--set-list',
    '--mask-def',
    '--aaf-bins',
    '--vc-tests',
    '--joint',
    '--build-mask',
    '--write-mask',
    '--vc-MACthr',
    '--vc-maxAAF'
  ]
  if (params.regenie_step2_optional && regenie_gene_based_cli_flags.any { flag -> params.regenie_step2_optional.toString().contains(flag) }) {
    error("REGENIE gene-based association workflow has been removed from this pipeline. Remove gene-based flags from --regenie_step2_optional.")
  }

  if (!(params.magma_gene_input_mode in ['sumstats', 'raw'])) {
    error("Unknown magma_gene_input_mode: ${params.magma_gene_input_mode}. Valid options: 'sumstats', 'raw'")
  }

  def shared_grm_dir = params.grm_dir ?: "${projectDir}/grm"
  def default_gcta_grm_prefix = "${shared_grm_dir}/gcta_grm/gcta_grm_0_adj_unrel05"
  def default_gcta_sparse_grm_prefix = "${shared_grm_dir}/gcta_grm_sparse/gcta_grm_0_adj_unrel05_sp"
  def default_gcta_mgrm_file = "${shared_grm_dir}/gcta_grm_ldms/gcta_grm_ldms.mgrm"
  def default_ldak_grm_prefix = "${shared_grm_dir}/ldak_grm/ldak_grm"
  def default_ldak_adjusted_grm_prefix = "${shared_grm_dir}/ldak_grm_adjusted/ldak_grm_adj"

  def resolved_gcta_grm_prefix = params.gcta_grm_prefix ?: default_gcta_grm_prefix
  def resolved_gcta_sparse_grm_prefix = params.gcta_sparse_grm_prefix ?: default_gcta_sparse_grm_prefix
  def resolved_gcta_mgrm_file = params.gcta_mgrm_file ?: default_gcta_mgrm_file
  def resolved_ldak_grm_prefix = params.ldak_grm_prefix ?: default_ldak_grm_prefix
  def resolved_ldak_adjusted_grm_prefix = params.ldak_adjusted_grm_prefix ?: default_ldak_adjusted_grm_prefix

  def fileExists = { pathStr ->
    pathStr != null && file(pathStr.toString(), checkIfExists: false).exists()
  }

  def gctaDenseExists = { prefix ->
    fileExists("${prefix}.grm.id") &&
    fileExists("${prefix}.grm.bin") &&
    fileExists("${prefix}.grm.N.bin")
  }

  def gctaSparseExists = { prefix ->
    fileExists("${prefix}.grm.id") &&
    fileExists("${prefix}.grm.sp")
  }

  def gctaMgrmExists = { mgrmPath ->
    if (!fileExists(mgrmPath)) {
      return false
    }

    def mgrmFile = file(mgrmPath, checkIfExists: false)
    def mgrmDir = mgrmFile.parent
    def prefixes = []

    mgrmFile.eachLine { rawLine ->
      def prefix = rawLine?.trim()
      if (!prefix || prefix.startsWith('#')) {
        return
      }
      prefixes << prefix
    }

    if (prefixes.isEmpty()) {
      return false
    }

    prefixes.every { prefix ->
      def isAbsolute = prefix.startsWith('/') || prefix ==~ /^[A-Za-z]:\\.*/
      def resolvedPrefix = isAbsolute ? prefix : "${mgrmDir}/${prefix}"
      gctaDenseExists(resolvedPrefix)
    }
  }

  def ldakBaseExists = { prefix ->
    fileExists("${prefix}.grm.bin") &&
    fileExists("${prefix}.grm.id") &&
    fileExists("${prefix}.grm.details") &&
    fileExists("${prefix}.grm.adjust") &&
    fileExists("${prefix}.keep")
  }

  def ldakAdjustedExists = { prefix ->
    fileExists("${prefix}.grm.bin") &&
    fileExists("${prefix}.grm.id") &&
    fileExists("${prefix}.grm.details") &&
    fileExists("${prefix}.grm.adjust") &&
    fileExists("${prefix}.grm.root") &&
    fileExists("${prefix}.keep")
  }

  // =============================================================================
  // COMMON DATA PREPARATION
  // =============================================================================

  // Use Ternary File pattern: phenotypes not required for summary-statistics-only workflows
  def needs_phenotypes = params.run_assoc_regenie ||
                         params.run_assoc_fastgwa ||
                         params.run_assoc_kvik ||
                         (params.run_magma_gene_based && params.magma_gene_input_mode == 'raw') ||
                         params.run_h2_gcta_greml ||
                         params.run_h2_gcta_greml_ldms ||
                         params.run_h2_bolt_lmm_reml ||
                         params.run_h2_ldak_reml ||
                         params.run_h2_ldak_he ||
                         params.run_h2_ldak_pcgc ||
                         params.run_h2_ldak_qc ||
                         params.run_rg_gcta_bivariate_greml ||
                         params.run_rg_gcta_bivariate_greml_ldms

  phenotype_meta_ch = Channel.empty()

  if (needs_phenotypes) {
    def phenotype_pattern = null
    if (params.phenotypes_dir) {
      phenotype_pattern = "${params.phenotypes_dir}/*"
    } else {
      error("Phenotype inputs are required. Please provide --phenotypes_dir with one file per phenotype.")
    }

    phenotype_files_ch = Channel.fromPath(phenotype_pattern, checkIfExists: true)
        .filter { it.isFile() }
        .filter { !it.name.contains('.noheader') }
        .ifEmpty { error("No phenotype files found at: ${phenotype_pattern}") }

    EXTRACT_PHENOTYPE_META(phenotype_files_ch)

    phenotype_meta_ch = EXTRACT_PHENOTYPE_META.out.phenotype_meta
        .map { phenotypes_file, meta_file ->
            def parts = meta_file.text.trim().split('\t')
            def phenotype_name = parts[0]
            def is_binary = parts[1].toLowerCase() == 'true'
            tuple(phenotype_name, phenotypes_file, is_binary)
        }
  }

  phenotype_meta_for_ldak_reml_ch = phenotype_meta_ch
  if (
    needs_phenotypes &&
    params.run_h2_ldak_reml &&
    params.ldak_reml_prevalence == null
  ) {
    phenotype_meta_for_ldak_reml_ch = phenotype_meta_ch.map { phenotype_name, phenotypes_file, is_binary ->
      if (is_binary) {
        println(ANSI_YELLOW + "WARN: Trait '${phenotype_name}' is binary and --run_h2_ldak_reml is enabled, but --ldak_reml_prevalence was not provided. REML runs without --prevalence (observed scale only)." + ANSI_RESET)
      }
      tuple(phenotype_name, phenotypes_file, is_binary)
    }
  }

  // Use Ternary File pattern: file object if provided, empty list [] if not
  covariates_file = params.covariates_filename ? file(params.covariates_filename, checkIfExists: true) : []

  // MAGMA reference panel and optional annotation inputs
  reference_plink_ch = Channel.empty()
  if (params.run_magma_gene_based && params.magma_gene_input_mode == 'sumstats') {
    if (!params.magma_reference_plink) {
      error("MAGMA gene-based analysis requires --magma_reference_plink parameter")
    }

    reference_plink_ch = Channel.fromFilePairs(params.magma_reference_plink, size: 3, checkIfExists: true)
      .toList()
      .flatMap { pairs ->
        if (pairs.size() != 1) {
          error("MAGMA reference panel must resolve to exactly one PLINK prefix. Found ${pairs.size()} matching groups from --magma_reference_plink")
        }
        return pairs
      }
      .map { reference_prefix, files ->
        def sortedFiles = files.sort { it.name }
        tuple(reference_prefix, sortedFiles[0], sortedFiles[1], sortedFiles[2])
      }
  }

  magma_gene_annot_file = params.magma_gene_annot ? file(params.magma_gene_annot, checkIfExists: true) : []
  magma_gene_loc_file = params.magma_gene_loc ? file(params.magma_gene_loc, checkIfExists: true) : []
  magma_set_annot_file = params.magma_set_annot ? file(params.magma_set_annot, checkIfExists: true) : []

  // Prepare genotyped PLINK channel for prediction-based methods
  genotyped_plink_ch = Channel.empty()
  def needs_genotyped_file = (!params.regenie_skip_predictions && params.run_assoc_regenie) || params.run_assoc_kvik
  if (needs_genotyped_file) {
    if (!genotyped_file) {
      error("Enabled workflows require --genotyped_file (PLINK bed/bim/fam pattern)")
    }
    genotyped_plink_ch = Channel.fromFilePairs(genotyped_file, size: 3, checkIfExists: true)
  }

  // =============================================================================
  // GENOTYPE FORMAT HANDLING
  // =============================================================================
  // Three input parameters supported (users can supply any combination):
  //   - imputed_genotyped_files_vcf:    VCF files (converted to PLINK1/PLINK2 if needed)
  //   - imputed_genotyped_files_plink1: PLINK1 files (bed/bim/fam) - used directly
  //   - imputed_genotyped_files_plink2: PLINK2 files (pgen/psam/pvar) - used directly
  //
  // Conversion logic:
  //   - If PLINK1 supplied: use directly, skip VCF→PLINK1 conversion
  //   - If PLINK2 supplied: use directly, skip VCF→PLINK2 conversion
  //   - If neither supplied but VCF provided: convert VCF to needed format(s)
  //   - If both PLINK1 and PLINK2 supplied: no conversions needed
  // =============================================================================

  imputed_plink2_ch = Channel.empty()
  imputed_plink_ch = Channel.empty()

  def needs_genotypes = params.run_assoc_regenie ||
                        params.run_assoc_fastgwa ||
                        params.run_assoc_kvik ||
                        params.run_h2_gcta_grm ||
                        params.run_h2_ldak_grm ||
                        params.run_h2_gcta_greml ||
                        params.run_h2_gcta_greml_ldms ||
                        params.run_h2_bolt_lmm_reml ||
                        params.run_h2_ldak_reml ||
                        params.run_h2_ldak_he ||
                        params.run_h2_ldak_pcgc ||
                        params.run_h2_ldak_qc ||
                        params.run_rg_gcta_bivariate_greml ||
                        params.run_rg_gcta_bivariate_greml_ldms ||
                        (params.run_magma_gene_based && params.magma_gene_input_mode == 'raw')

  if (needs_genotypes) {

    // Determine which formats are provided
    def has_vcf = imputed_genotyped_files_vcf != null
    def has_plink1 = params.imputed_genotyped_files_plink1 != null
    def has_plink2 = params.imputed_genotyped_files_plink2 != null

    // Validate at least one input is provided
    if (!has_vcf && !has_plink1 && !has_plink2) {
      error("No genotype files provided. Please specify at least one of: imputed_genotyped_files_vcf, imputed_genotyped_files_plink1, or imputed_genotyped_files_plink2")
    }

    // Print input format summary
    println(ANSI_GREEN + "=== Genotype Input ===" + ANSI_RESET)
    if (has_vcf) println(ANSI_GREEN + "  VCF files: ${imputed_genotyped_files_vcf}" + ANSI_RESET)
    if (has_plink1) println(ANSI_GREEN + "  PLINK1 files: ${params.imputed_genotyped_files_plink1}" + ANSI_RESET)
    if (has_plink2) println(ANSI_GREEN + "  PLINK2 files: ${params.imputed_genotyped_files_plink2}" + ANSI_RESET)

    // --------------------------------------------------------------------------
    // STEP 1: Load user-supplied PLINK1 files (if provided)
    // --------------------------------------------------------------------------
    if (has_plink1) {
      println(ANSI_GREEN + "  → Using supplied PLINK1 files directly" + ANSI_RESET)

      // Custom key extraction to handle filenames with multiple dots (e.g., chr01.vcf.bed)
      // By default, fromFilePairs uses simple basename extraction which fails for such patterns
      imputed_plink_ch = Channel.fromFilePairs(params.imputed_genotyped_files_plink1, size: 3, checkIfExists: true) { file ->
          file.name.replaceAll(/\.(bed|bim|fam)$/, '')
        }
        .toList()
        .flatMap { pairs ->
          // Prefer double-digit chromosome tags in filenames (e.g., chr01),
          // but allow generic names for workflows that can operate on merged inputs.
          def invalid_files = pairs.findAll { name, files -> !(name =~ /\d{2}/) }
          if (invalid_files) {
            log.warn("PLINK1 files without double digit numbers found: ${invalid_files.collect { it[0] }.join(', ')}; proceeding with lexical ordering")
          }

          // Sort by name and assign chromosome numbers
          // Output format: [chr_num, basename, bed, bim, fam, range]
          return pairs
            .sort { it[0] }
            .withIndex(1)
            .collect { pair, index ->
              def (basename, files) = pair
              def sortedFiles = files.sort { it.name }
              [index, basename, sortedFiles[0], sortedFiles[1], sortedFiles[2], -1]
            }
        }
    }

    // --------------------------------------------------------------------------
    // STEP 2: Load user-supplied PLINK2 files (if provided)
    // --------------------------------------------------------------------------
    if (has_plink2) {
      println(ANSI_GREEN + "  → Using supplied PLINK2 files directly" + ANSI_RESET)

      // Custom key extraction to handle filenames with multiple dots (e.g., chr01.vcf.pgen)
      // By default, fromFilePairs uses simple basename extraction which fails for such patterns
      imputed_plink2_ch = Channel.fromFilePairs(params.imputed_genotyped_files_plink2, size: 3, checkIfExists: true) { file ->
          file.name.replaceAll(/\.(pgen|psam|pvar)$/, '')
        }
        .toList()
        .flatMap { pairs ->
          // Prefer double-digit chromosome tags in filenames (e.g., chr01),
          // but allow generic names for workflows that can operate on merged inputs.
          def invalid_files = pairs.findAll { name, files -> !(name =~ /\d{2}/) }
          if (invalid_files) {
            log.warn("PLINK2 files without double digit numbers found: ${invalid_files.collect { it[0] }.join(', ')}; proceeding with lexical ordering")
          }

          // Sort by name and assign chromosome numbers
          // Output format: [chr_num, basename, pgen, psam, pvar, range]
          return pairs
            .sort { it[0] }
            .withIndex(1)
            .collect { pair, index ->
              def (basename, files) = pair
              def sortedFiles = files.sort { it.name }
              [index, basename, sortedFiles[0], sortedFiles[1], sortedFiles[2], -1]
            }
        }
    }

    // --------------------------------------------------------------------------
    // STEP 3: Convert VCF to missing formats (if VCF provided and format not supplied)
    // --------------------------------------------------------------------------
    if (has_vcf) {
      // Load VCF files
      imputed_files_ch = channel.fromPath(imputed_genotyped_files_vcf, checkIfExists: true)
        .toList()
        .flatMap { files ->
          def invalid_files = files.findAll { file -> !(file.name =~ /\d{2}/) }
          if (invalid_files) {
            log.warn("VCF files without double digit numbers found: ${invalid_files.collect { it.name }.join(', ')}; proceeding with lexical ordering")
          }
          return files.sort { it.name }.withIndex(1).collect { file, index -> [index, file] }
        }

      // Convert VCF to PLINK1 if not supplied
      if (!has_plink1) {
        println(ANSI_GREEN + "  → Converting VCF to PLINK1" + ANSI_RESET)
        IMPUTED_TO_PLINK(imputed_files_ch)
        imputed_plink_ch = IMPUTED_TO_PLINK.out.imputed_plink
      }

      // Convert VCF to PLINK2 if not supplied
      if (!has_plink2) {
        println(ANSI_GREEN + "  → Converting VCF to PLINK2" + ANSI_RESET)
        IMPUTED_TO_PLINK2(imputed_files_ch)
        imputed_plink2_ch = IMPUTED_TO_PLINK2.out.imputed_plink2
      }
    }

    // --------------------------------------------------------------------------
    // STEP 4: Cross-convert between PLINK formats if needed
    // --------------------------------------------------------------------------
    // If only PLINK1 provided (no VCF, no PLINK2), convert PLINK1 → PLINK2
    if (has_plink1 && !has_plink2 && !has_vcf) {
      println(ANSI_GREEN + "  → Converting PLINK1 to PLINK2" + ANSI_RESET)
      PLINK1_TO_PLINK2(imputed_plink_ch)
      imputed_plink2_ch = PLINK1_TO_PLINK2.out.plink2
    }

    // If only PLINK2 provided (no VCF, no PLINK1), convert PLINK2 → PLINK1
    if (has_plink2 && !has_plink1 && !has_vcf) {
      println(ANSI_GREEN + "  → Converting PLINK2 to PLINK1" + ANSI_RESET)
      PLINK2_TO_PLINK1(imputed_plink2_ch)
      imputed_plink_ch = PLINK2_TO_PLINK1.out.plink1
    }

    println(ANSI_GREEN + "======================" + ANSI_RESET)
  }

  magma_raw_plink_ch = Channel.empty()
  if (params.run_magma_gene_based && params.magma_gene_input_mode == 'raw') {
    magma_raw_plink_ch = imputed_plink_ch.map { _chr_num, filename, bed, bim, fam, _range ->
      tuple(filename, bed, bim, fam)
    }
  }

  // Define genotypes association format (now 'bed' for PLINK1 format used by REGENIE)
  def genotypes_association_format = 'bed'

  // =============================================================================
  // 1. ASSOCIATION WORKFLOWS
  // =============================================================================
  regenie_results_ch = Channel.empty()
  regenie_merged_results_ch = Channel.empty()
  fastgwa_results_ch = Channel.empty()
  kvik_assoc_results_ch = Channel.empty()
  generated_sumstats_ch = Channel.empty()

  if (params.run_assoc_regenie) {
    println(ANSI_GREEN + "▶ Running Association Workflow: REGENIE" + ANSI_RESET)
    SINGLE_VARIANT_TESTS(
      imputed_plink_ch,
      phenotype_meta_ch,
      covariates_file,
      genotyped_plink_ch,
      params.genotypes_build,
      genotypes_association_format,
      params.regenie_skip_predictions
    )

    regenie_results_ch = SINGLE_VARIANT_TESTS.out.regenie_step2_results
    regenie_merged_results_ch = SINGLE_VARIANT_TESTS.out.merged_results
    generated_sumstats_ch = generated_sumstats_ch.mix(
      SINGLE_VARIANT_TESTS.out.merged_results.map { trait_name, merged_file ->
        tuple(trait_name, 'regenie', merged_file)
      }
    )
  }

  if (params.run_assoc_fastgwa) {
    if (gctaSparseExists(resolved_gcta_sparse_grm_prefix)) {
      println(ANSI_GREEN + "▶ Running Association Workflow: GCTA FastGWA (using existing sparse GRM at ${resolved_gcta_sparse_grm_prefix})" + ANSI_RESET)
      sparse_grm_files_ch = Channel.of(tuple(
        file("${resolved_gcta_sparse_grm_prefix}.grm.id", checkIfExists: true),
        file("${resolved_gcta_sparse_grm_prefix}.grm.sp", checkIfExists: true)
      ))

      GCTA_FASTGWA_ANALYSIS(
        imputed_plink2_ch,
        sparse_grm_files_ch,
        phenotype_meta_ch,
        covariates_file
      )

      fastgwa_results_ch = GCTA_FASTGWA_ANALYSIS.out.fastgwa_results
    } else {
      println(ANSI_GREEN + "▶ Running Association Workflow: GCTA FastGWA (sparse GRM not found at ${resolved_gcta_sparse_grm_prefix}; computing GRM)" + ANSI_RESET)
      GCTA_FASTGWA(
        imputed_plink2_ch,
        phenotype_meta_ch,
        covariates_file,
        params.nparts_gcta,
        0.05
      )

      fastgwa_results_ch = GCTA_FASTGWA.out.fastgwa_results

      SYNC_GCTA_SPARSE_GRM_LINKS(
        GCTA_FASTGWA.out.sparse_grm_files,
        shared_grm_dir
      )
    }

    generated_sumstats_ch = generated_sumstats_ch.mix(
      fastgwa_results_ch.map { fastgwa_file ->
        def trait_name = fastgwa_file.baseName.replaceAll(/.*_([^_]+)\.fastGWA$/, '$1')
        tuple(trait_name, 'fastgwa', fastgwa_file)
      }
    )
  }

  if (params.run_assoc_kvik) {
    println(ANSI_GREEN + "▶ Running Association Workflow: LDAK KVIK" + ANSI_RESET)

    step1_plink_for_kvik_ch = genotyped_plink_ch
      .toList()
      .flatMap { pairs ->
        if (!pairs || pairs.isEmpty()) {
          error("LDAK KVIK requires --genotyped_file")
        }
        return pairs.take(1)
      }

    LDAK_KVIK_WORKFLOW(
      step1_plink_for_kvik_ch,
      imputed_plink_ch,
      phenotype_meta_ch,
      covariates_file
    )

    kvik_assoc_results_ch = LDAK_KVIK_WORKFLOW.out.merged_assoc
    generated_sumstats_ch = generated_sumstats_ch.mix(
      LDAK_KVIK_WORKFLOW.out.merged_assoc.map { trait_name, assoc_file ->
        tuple(trait_name, 'kvik', assoc_file)
      }
    )
  }

  synced_sumstats_ch = Channel.empty()
  if (params.run_assoc_regenie || params.run_assoc_fastgwa || params.run_assoc_kvik) {
    SYNC_SUMSTATS_LINKS(
      generated_sumstats_ch,
      params.summary_stats_dir
    )
    synced_sumstats_ch = SYNC_SUMSTATS_LINKS.out.linked_sumstats
  }

  existing_summary_stats_ch = Channel.fromPath("${params.summary_stats_dir}/*", checkIfExists: false)
    .filter { it.isFile() }
    .map { stats_file ->
      def trait_name = stats_file.baseName.replaceAll(/\..*/, '')
      tuple(trait_name, stats_file)
    }

  all_summary_stats_ch = existing_summary_stats_ch.mix(synced_sumstats_ch)

  // =============================================================================
  // 2. GENE-BASED ASSOCIATIONS (MAGMA)
  // =============================================================================
  magma_gene_results_ch = Channel.empty()
  magma_gene_results_raw_ch = Channel.empty()

  if (params.run_magma_gene_based) {
    println(ANSI_GREEN + "▶ Running MAGMA gene-based workflow" + ANSI_RESET)

    if (magma_gene_annot_file == [] && magma_gene_loc_file == []) {
      error("MAGMA gene-based analysis requires --magma_gene_annot or --magma_gene_loc")
    }

    if (params.magma_gene_input_mode == 'raw') {
      MAGMA_GENE_BASED_RAW(
        phenotype_meta_ch,
        magma_raw_plink_ch,
        magma_gene_annot_file,
        magma_gene_loc_file,
        covariates_file
      )

      magma_gene_results_ch = MAGMA_GENE_BASED_RAW.out.gene_results
      magma_gene_results_raw_ch = MAGMA_GENE_BASED_RAW.out.gene_results_raw
    } else {
      summary_stats_for_magma_ch = all_summary_stats_ch
        .ifEmpty { error("No summary statistics files found for MAGMA in ${params.summary_stats_dir}") }

      MAGMA_GENE_BASED(
        summary_stats_for_magma_ch,
        reference_plink_ch,
        magma_gene_annot_file,
        magma_gene_loc_file
      )

      magma_gene_results_ch = MAGMA_GENE_BASED.out.gene_results
      magma_gene_results_raw_ch = MAGMA_GENE_BASED.out.gene_results_raw
    }
  }

  magma_geneset_results_ch = Channel.empty()
  if (params.run_magma_gene_set) {
    println(ANSI_GREEN + "▶ Running MAGMA gene-set workflow" + ANSI_RESET)

    if (magma_set_annot_file == []) {
      error("MAGMA gene-set analysis requires --magma_set_annot")
    }

    gene_results_for_set_ch = Channel.empty()
    if (params.magma_gene_results_dir) {
      gene_results_for_set_ch = Channel.fromPath("${params.magma_gene_results_dir}/*.genes.raw", checkIfExists: true)
        .filter { it.isFile() }
        .ifEmpty { error("No *.genes.raw files found at: ${params.magma_gene_results_dir}") }
        .map { gene_file ->
          def trait_name = gene_file.baseName.replaceAll(/\..*/, '')
          tuple(trait_name, gene_file)
        }
    } else {
      if (!params.run_magma_gene_based) {
        error("MAGMA gene-set analysis requires --run_magma_gene_based true or --magma_gene_results_dir")
      }
      gene_results_for_set_ch = magma_gene_results_raw_ch
    }

    MAGMA_GENE_SET(
      gene_results_for_set_ch,
      magma_set_annot_file
    )

    magma_geneset_results_ch = MAGMA_GENE_SET.out.geneset_results
  }

  // =============================================================================
  // 3. HERITABILITY WORKFLOWS
  // =============================================================================
  grm_results_ch = Channel.empty()
  heritability_results_ch = Channel.empty()
  heritability_inflation_ch = Channel.empty()

  if (params.run_h2_gcta_grm) {
    println(ANSI_GREEN + "▶ Running GCTA GRM workflow" + ANSI_RESET)
    GCTA_GRM(
      imputed_plink2_ch,
      params.nparts_gcta,
      Channel.of(["0", []]),
      params.gcta_create_sparse_grm,
      params.gcta_sparse_cutoff,
      false
    )
    grm_results_ch = grm_results_ch.mix(GCTA_GRM.out.grm_files)

    SYNC_GCTA_GRM_LINKS(
      GCTA_GRM.out.grm_files,
      shared_grm_dir
    )
  }

  if (params.run_h2_ldak_grm) {
    println(ANSI_GREEN + "▶ Running LDAK GRM workflow" + ANSI_RESET)
    LDAK_GRM(
      imputed_plink_ch,
      params.heritability_model
    )
    grm_results_ch = grm_results_ch.mix(LDAK_GRM.out.combined_grm)

    ldak_combined_grm_with_keep_ch = LDAK_GRM.out.combined_grm
      .join(LDAK_GRM.out.filtered_list, by: [0])
      .map { row ->
        tuple(row[0], row[1], row[2], row[3], row[4], row[5])
      }

    SYNC_LDAK_GRM_LINKS(
      ldak_combined_grm_with_keep_ch,
      shared_grm_dir
    )
  }

  if (params.run_h2_gcta_greml) {
    if (gctaDenseExists(resolved_gcta_grm_prefix)) {
      println(ANSI_GREEN + "▶ Running GCTA GREML (using existing GRM at ${resolved_gcta_grm_prefix})" + ANSI_RESET)
      grm_files_ch = Channel.of(tuple(
        "0",
        resolved_gcta_grm_prefix,
        file("${resolved_gcta_grm_prefix}.grm.id", checkIfExists: true),
        file("${resolved_gcta_grm_prefix}.grm.bin", checkIfExists: true),
        file("${resolved_gcta_grm_prefix}.grm.N.bin", checkIfExists: true)
      ))
      GCTA_REML_ANALYSIS(grm_files_ch, phenotype_meta_ch, covariates_file)
      heritability_results_ch = heritability_results_ch.mix(GCTA_REML_ANALYSIS.out.reml_results)
    } else {
      println(ANSI_GREEN + "▶ Running GCTA GREML (GRM not found at ${resolved_gcta_grm_prefix}; computing GRM)" + ANSI_RESET)
      GCTA_GREML(phenotype_meta_ch, covariates_file, imputed_plink2_ch, params.nparts_gcta)
      grm_results_ch = grm_results_ch.mix(GCTA_GREML.out.grm_files)
      heritability_results_ch = heritability_results_ch.mix(GCTA_GREML.out.reml_results)
    }
  }

  if (params.run_h2_gcta_greml_ldms) {
    if (gctaMgrmExists(resolved_gcta_mgrm_file)) {
      println(ANSI_GREEN + "▶ Running GCTA GREML-LDMS (using existing MGRM at ${resolved_gcta_mgrm_file})" + ANSI_RESET)
      mgrm_file = file(resolved_gcta_mgrm_file, checkIfExists: true)
      mgrm_file_ch = Channel.of(mgrm_file)
      def mgrm_dir = mgrm_file.parent
      all_grm_files_ch = Channel.fromPath(resolved_gcta_mgrm_file)
        .splitText()
        .map { prefix ->
          prefix = prefix.trim()
          def grm_path = "${mgrm_dir}/${prefix}"
          [
            file("${grm_path}.grm.id", checkIfExists: true),
            file("${grm_path}.grm.bin", checkIfExists: true),
            file("${grm_path}.grm.N.bin", checkIfExists: true)
          ]
        }
        .flatten()
        .collect()
      GCTA_REML_LDMS_ANALYSIS(mgrm_file_ch, all_grm_files_ch, phenotype_meta_ch, covariates_file)
      heritability_results_ch = heritability_results_ch.mix(GCTA_REML_LDMS_ANALYSIS.out.reml_results)
    } else {
      println(ANSI_GREEN + "▶ Running GCTA GREML-LDMS (MGRM not found at ${resolved_gcta_mgrm_file}; computing GRMs)" + ANSI_RESET)
      GCTA_GREML_LDMS(phenotype_meta_ch, covariates_file, imputed_plink2_ch, imputed_plink_ch, params.nparts_gcta)
      grm_results_ch = grm_results_ch.mix(GCTA_GREML_LDMS.out.grm_files)
      heritability_results_ch = heritability_results_ch.mix(GCTA_GREML_LDMS.out.reml_results)

      SYNC_GCTA_GRM_LDMS_LINKS(
        GCTA_GREML_LDMS.out.grm_files,
        shared_grm_dir
      )
    }
  }

  if (params.run_h2_bolt_lmm_reml) {
    BOLT_LMM_REML(imputed_plink_ch, phenotype_meta_ch, covariates_file)
  }

  if (params.run_h2_ldak_reml) {
    if (ldakBaseExists(resolved_ldak_grm_prefix)) {
      println(ANSI_GREEN + "▶ Running LDAK REML (using existing GRM at ${resolved_ldak_grm_prefix})" + ANSI_RESET)
      combined_grm_ch = Channel.of(tuple(
        resolved_ldak_grm_prefix,
        file("${resolved_ldak_grm_prefix}.grm.bin", checkIfExists: true),
        file("${resolved_ldak_grm_prefix}.grm.id", checkIfExists: true),
        file("${resolved_ldak_grm_prefix}.grm.details", checkIfExists: true),
        file("${resolved_ldak_grm_prefix}.grm.adjust", checkIfExists: true)
      ))
      filtered_list = file("${resolved_ldak_grm_prefix}.keep", checkIfExists: true)
      LDAK_REML_ANALYSIS(combined_grm_ch, filtered_list, phenotype_meta_for_ldak_reml_ch, covariates_file)
      heritability_results_ch = heritability_results_ch.mix(LDAK_REML_ANALYSIS.out.reml_results)
    } else {
      println(ANSI_GREEN + "▶ Running LDAK REML (GRM not found at ${resolved_ldak_grm_prefix}; computing GRM)" + ANSI_RESET)
      LDAK_REML_WORKFLOW(imputed_plink_ch, phenotype_meta_for_ldak_reml_ch, covariates_file, params.heritability_model)
      grm_results_ch = grm_results_ch.mix(LDAK_REML_WORKFLOW.out.combined_grm)
      heritability_results_ch = heritability_results_ch.mix(LDAK_REML_WORKFLOW.out.reml_results)
    }
  }

  if (params.run_h2_ldak_he) {
    if (ldakAdjustedExists(resolved_ldak_adjusted_grm_prefix)) {
      println(ANSI_GREEN + "▶ Running LDAK HE (using existing adjusted GRM at ${resolved_ldak_adjusted_grm_prefix})" + ANSI_RESET)
      grm_prefix = resolved_ldak_adjusted_grm_prefix
      filtered_list = file("${grm_prefix}.keep", checkIfExists: true)
      grm_ch = Channel.of(tuple(
        grm_prefix,
        file("${grm_prefix}.grm.bin", checkIfExists: true),
        file("${grm_prefix}.grm.id", checkIfExists: true),
        file("${grm_prefix}.grm.details", checkIfExists: true),
        file("${grm_prefix}.grm.adjust", checkIfExists: true),
        file("${grm_prefix}.grm.root", checkIfExists: true)
      ))
      LDAK_HE_ANALYSIS(grm_ch, filtered_list, phenotype_meta_ch, covariates_file)
      heritability_results_ch = heritability_results_ch.mix(LDAK_HE_ANALYSIS.out.he_results)
    } else if (ldakBaseExists(resolved_ldak_grm_prefix)) {
      println(ANSI_GREEN + "▶ Running LDAK HE (using existing base GRM at ${resolved_ldak_grm_prefix}; adjusted GRM not found)" + ANSI_RESET)
      grm_prefix = resolved_ldak_grm_prefix
      filtered_list = file("${grm_prefix}.keep", checkIfExists: true)
      grm_ch = Channel.of(tuple(
        grm_prefix,
        file("${grm_prefix}.grm.bin", checkIfExists: true),
        file("${grm_prefix}.grm.id", checkIfExists: true),
        file("${grm_prefix}.grm.details", checkIfExists: true),
        file("${grm_prefix}.grm.adjust", checkIfExists: true)
      ))
      LDAK_HE_ANALYSIS(grm_ch, filtered_list, phenotype_meta_ch, covariates_file)
      heritability_results_ch = heritability_results_ch.mix(LDAK_HE_ANALYSIS.out.he_results)
    } else {
      println(ANSI_GREEN + "▶ Running LDAK HE (GRMs not found at ${resolved_ldak_adjusted_grm_prefix} or ${resolved_ldak_grm_prefix}; computing GRM)" + ANSI_RESET)
      LDAK_HE_WORKFLOW(imputed_plink_ch, phenotype_meta_ch, covariates_file, params.heritability_model)
      grm_results_ch = grm_results_ch.mix(LDAK_HE_WORKFLOW.out.combined_grm)
      heritability_results_ch = heritability_results_ch.mix(LDAK_HE_WORKFLOW.out.he_results)
    }
  }

  if (params.run_h2_ldak_pcgc) {
    if (params.ldak_pcgc_prevalence == null) {
      error("LDAK PCGC requires --ldak_pcgc_prevalence")
    }
    if (ldakAdjustedExists(resolved_ldak_adjusted_grm_prefix)) {
      println(ANSI_GREEN + "▶ Running LDAK PCGC (using existing adjusted GRM at ${resolved_ldak_adjusted_grm_prefix})" + ANSI_RESET)
      grm_prefix = resolved_ldak_adjusted_grm_prefix
      filtered_list = file("${grm_prefix}.keep", checkIfExists: true)
      grm_ch = Channel.of(tuple(
        grm_prefix,
        file("${grm_prefix}.grm.bin", checkIfExists: true),
        file("${grm_prefix}.grm.id", checkIfExists: true),
        file("${grm_prefix}.grm.details", checkIfExists: true),
        file("${grm_prefix}.grm.adjust", checkIfExists: true),
        file("${grm_prefix}.grm.root", checkIfExists: true)
      ))
      LDAK_PCGC_ANALYSIS(grm_ch, filtered_list, phenotype_meta_ch, covariates_file)
      heritability_results_ch = heritability_results_ch.mix(LDAK_PCGC_ANALYSIS.out.pcgc_results)
    } else if (ldakBaseExists(resolved_ldak_grm_prefix)) {
      println(ANSI_GREEN + "▶ Running LDAK PCGC (using existing base GRM at ${resolved_ldak_grm_prefix}; adjusted GRM not found)" + ANSI_RESET)
      grm_prefix = resolved_ldak_grm_prefix
      filtered_list = file("${grm_prefix}.keep", checkIfExists: true)
      grm_ch = Channel.of(tuple(
        grm_prefix,
        file("${grm_prefix}.grm.bin", checkIfExists: true),
        file("${grm_prefix}.grm.id", checkIfExists: true),
        file("${grm_prefix}.grm.details", checkIfExists: true),
        file("${grm_prefix}.grm.adjust", checkIfExists: true)
      ))
      LDAK_PCGC_ANALYSIS(grm_ch, filtered_list, phenotype_meta_ch, covariates_file)
      heritability_results_ch = heritability_results_ch.mix(LDAK_PCGC_ANALYSIS.out.pcgc_results)
    } else {
      println(ANSI_GREEN + "▶ Running LDAK PCGC (GRMs not found at ${resolved_ldak_adjusted_grm_prefix} or ${resolved_ldak_grm_prefix}; computing GRM)" + ANSI_RESET)
      LDAK_PCGC_WORKFLOW(imputed_plink_ch, phenotype_meta_ch, covariates_file, params.heritability_model)
      grm_results_ch = grm_results_ch.mix(LDAK_PCGC_WORKFLOW.out.combined_grm)
      heritability_results_ch = heritability_results_ch.mix(LDAK_PCGC_WORKFLOW.out.pcgc_results)
    }
  }

  if (params.run_h2_ldak_qc) {
    LDAK_QC(imputed_plink_ch, phenotype_meta_ch, covariates_file)
    heritability_results_ch = heritability_results_ch.mix(LDAK_QC.out.quarter_reml_results)
    heritability_inflation_ch = heritability_inflation_ch.mix(LDAK_QC.out.inflation_results)
  }

  if (params.run_h2_ldak_sumher) {
    if (params.ldak_sumher_tagfile == null) {
      error("LDAK SumHer requires --ldak_sumher_tagfile")
    }

    def sumherTraitPrevalenceMap = parseTraitProportionFile(
      params.ldak_sumher_prevalence_map,
      'LDAK SumHer',
      'prevalence'
    )
    def sumherTraitAscertainmentMap = parseTraitProportionFile(
      params.ldak_sumher_ascertainment_map,
      'LDAK SumHer',
      'ascertainment'
    )
    def useSumherPrevalenceMap = params.ldak_sumher_prevalence_map != null
    def useSumherAscertainmentMap = params.ldak_sumher_ascertainment_map != null

    if (useSumherPrevalenceMap && params.ldak_sumher_prevalence != null) {
      println(ANSI_YELLOW + "WARN: Both --ldak_sumher_prevalence_map and --ldak_sumher_prevalence were provided. Map-based prevalence is used." + ANSI_RESET)
    }
    if (useSumherAscertainmentMap && params.ldak_sumher_ascertainment != null) {
      println(ANSI_YELLOW + "WARN: Both --ldak_sumher_ascertainment_map and --ldak_sumher_ascertainment were provided. Map-based ascertainment is used." + ANSI_RESET)
    }

    sumher_summary_stats_ch = all_summary_stats_ch
      .ifEmpty { error("LDAK SumHer requires summary statistics in ${params.summary_stats_dir}") }
      .map { trait_name, stats_file ->
        def prevalence_override = useSumherPrevalenceMap ? sumherTraitPrevalenceMap[stats_file.name] : params.ldak_sumher_prevalence?.toString()
        def ascertainment_override = useSumherAscertainmentMap ? sumherTraitAscertainmentMap[stats_file.name] : params.ldak_sumher_ascertainment?.toString()
        tuple(trait_name, stats_file, prevalence_override, ascertainment_override)
      }

    LDAK_SUMHER_WORKFLOW(sumher_summary_stats_ch, file(params.ldak_sumher_tagfile))
    heritability_results_ch = heritability_results_ch.mix(LDAK_SUMHER_WORKFLOW.out.heritability_results)
  }

  if (params.run_h2_ldsc_h2) {
    ldsc_h2_input_ch = all_summary_stats_ch
      .ifEmpty { error("LDSC h2 requires summary statistics in ${params.summary_stats_dir}") }
    LDSC_H2_WORKFLOW(ldsc_h2_input_ch)
    heritability_results_ch = heritability_results_ch.mix(LDSC_H2_WORKFLOW.out.heritability_results)
  }

  // =============================================================================
  // 4. GENETIC CORRELATION WORKFLOWS
  // =============================================================================
  genetic_correlation_results_ch = Channel.empty()

  if (params.run_rg_ldak_sumcors || params.run_rg_ldsc_rg) {
    summary_stats_pairs_ch = all_summary_stats_ch
      .map { _trait_name, stats_file -> stats_file }
      .toList()
      .flatMap { files ->
        if (files.size() < 2) {
          error("Genetic correlation workflows require at least two summary statistic files in ${params.summary_stats_dir}")
        }
        def sorted = files.sort { it.name }
        def pairs = []
        for (int i = 0; i < sorted.size() - 1; i++) {
          for (int j = i + 1; j < sorted.size(); j++) {
            def f1 = sorted[i]
            def f2 = sorted[j]
            def trait1_name = f1.baseName.replaceAll(/\..*/, '')
            def trait2_name = f2.baseName.replaceAll(/\..*/, '')
            pairs << tuple(trait1_name, f1, trait2_name, f2)
          }
        }
        pairs
      }

    if (params.run_rg_ldak_sumcors) {
      if (params.ldak_sumcors_tagfile == null) {
        error("LDAK SumCors requires --ldak_sumcors_tagfile")
      }
      LDAK_SUMCORS_WORKFLOW(summary_stats_pairs_ch, file(params.ldak_sumcors_tagfile))
      genetic_correlation_results_ch = genetic_correlation_results_ch.mix(LDAK_SUMCORS_WORKFLOW.out.correlation_results)
    }

    if (params.run_rg_ldsc_rg) {
      LDSC_RG_WORKFLOW(summary_stats_pairs_ch)
      genetic_correlation_results_ch = genetic_correlation_results_ch.mix(LDSC_RG_WORKFLOW.out.correlation_results)
    }
  }

  if (params.run_rg_gcta_bivariate_greml || params.run_rg_gcta_bivariate_greml_ldms) {
    phenotype_pairs_ch = phenotype_meta_ch
      .toList()
      .flatMap { phenos ->
        if (phenos.size() < 2) {
          error("GCTA bivariate workflows require at least two phenotype files in --phenotypes_dir")
        }
        def sorted = phenos.sort { it[0] }
        def pairs = []
        for (int i = 0; i < sorted.size() - 1; i++) {
          for (int j = i + 1; j < sorted.size(); j++) {
            def p1 = sorted[i]
            def p2 = sorted[j]
            pairs << tuple(p1[0], p1[1], p1[2], p2[0], p2[1], p2[2])
          }
        }
        pairs
      }

    if (params.run_rg_gcta_bivariate_greml) {
      GCTA_BIVARIATE_GREML(phenotype_pairs_ch, covariates_file, imputed_plink2_ch, params.nparts_gcta)
      genetic_correlation_results_ch = genetic_correlation_results_ch.mix(GCTA_BIVARIATE_GREML.out.bivariate_results)
    }

    if (params.run_rg_gcta_bivariate_greml_ldms) {
      GCTA_BIVARIATE_GREML_LDMS(phenotype_pairs_ch, covariates_file, imputed_plink2_ch, imputed_plink_ch, params.nparts_gcta)
      genetic_correlation_results_ch = genetic_correlation_results_ch.mix(GCTA_BIVARIATE_GREML_LDMS.out.bivariate_results)
    }
  }

  // =============================================================================
  // 5. OTHER WORKFLOWS
  // =============================================================================
  other_results_ch = Channel.empty()

  if (params.run_lava_local_rg) {
    if (!params.lava_ref_plink || !params.lava_loci_file) {
      error("LAVA requires --lava_ref_plink and --lava_loci_file")
    }

    lava_ref_plink_ch = Channel.fromFilePairs(params.lava_ref_plink, size: 3, checkIfExists: true)
      .toList()
      .flatMap { pairs ->
        if (pairs.size() != 1) {
          error("LAVA reference PLINK must resolve to exactly one prefix")
        }
        pairs
      }
      .map { _prefix, files ->
        def sortedFiles = files.sort { it.name }
        tuple(sortedFiles[0], sortedFiles[1], sortedFiles[2])
      }

    lava_sumstats_list_ch = all_summary_stats_ch
      .map { _trait_name, stats_file -> stats_file }
      .toList()
      .ifEmpty { error("LAVA requires summary statistics in ${params.summary_stats_dir}") }

    lava_phenotype_info_ch = all_summary_stats_ch
      .map { trait_name, stats_file -> [name: trait_name, cases: null, controls: null, prevalence: null, filename: stats_file.name] }
      .toList()
      .map { rows -> groovy.json.JsonOutput.toJson(rows) }

    LAVA_LOCAL_RG(
      params.lava_analysis_id,
      lava_ref_plink_ch,
      lava_sumstats_list_ch,
      file(params.lava_loci_file, checkIfExists: true),
      params.lava_sample_overlap_file ? file(params.lava_sample_overlap_file, checkIfExists: true) : [],
      lava_phenotype_info_ch,
      params.lava_univ_threshold
    )

    other_results_ch = other_results_ch.mix(LAVA_LOCAL_RG.out.univ_results).mix(LAVA_LOCAL_RG.out.bivar_results)
  }

  if (params.run_lcv_causal) {
    if (!params.lcv_ldscores_file || !params.lcv_sumstats_trait1 || !params.lcv_sumstats_trait2 || !params.lcv_trait1_name || !params.lcv_trait2_name) {
      error("LCV requires --lcv_ldscores_file, --lcv_sumstats_trait1, --lcv_sumstats_trait2, --lcv_trait1_name, --lcv_trait2_name")
    }

    LCV_CAUSAL(
      params.lcv_analysis_id,
      file(params.lcv_sumstats_trait1, checkIfExists: true),
      file(params.lcv_sumstats_trait2, checkIfExists: true),
      file(params.lcv_ldscores_file, checkIfExists: true),
      params.lcv_trait1_name,
      params.lcv_trait2_name,
      params.lcv_no_blocks,
      params.lcv_sig_threshold,
      params.lcv_crosstrait_intercept,
      params.lcv_ldsc_intercept
    )

    other_results_ch = other_results_ch.mix(LCV_CAUSAL.out.results)
  }

  // =============================================================================
  // OUTPUT EMISSIONS
  // =============================================================================
  emit:
  grm_results = grm_results_ch
  association_results = regenie_results_ch.mix(fastgwa_results_ch).mix(kvik_assoc_results_ch)
  synced_summary_stats = synced_sumstats_ch
  gene_based_results = magma_gene_results_ch
  gene_set_results = magma_geneset_results_ch
  heritability_results = heritability_results_ch
  heritability_inflation = heritability_inflation_ch
  genetic_correlation_results = genetic_correlation_results_ch
  other_results = other_results_ch
}
