// =============================================================================
// DATA CONVERSION MODULES
// =============================================================================
include { IMPUTED_TO_PLINK2 } from '../modules/local/imputed_to_plink2'
include { IMPUTED_TO_PLINK } from '../modules/local/imputed_to_plink'
include { PLINK1_TO_PLINK2 } from '../modules/local/plink1_to_plink2'
include { PLINK2_TO_PLINK1 } from '../modules/local/plink2_to_plink1'

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

// =============================================================================
// 3. GENETIC CORRELATION WORKFLOWS
// =============================================================================
include { LDAK_SUMCORS_WORKFLOW } from './ldak/ldak_sumcors'
include { GCTA_BIVARIATE_GREML } from './gcta/gcta_bivariate_greml'
include { GCTA_BIVARIATE_GREML_LDMS } from './gcta/gcta_bivariate_greml_ldms'

// =============================================================================
// MAIN WORKFLOW
// =============================================================================
workflow NF_GWAS {

  main:
  // =============================================================================
  // INITIALIZATION AND INPUT VALIDATION
  // =============================================================================
  println("Output directory: ${params.pubDir}")
  println("\n=== Analysis Configuration ===")
  println("GRM-Only Computation: ${params.run_grm_only ? 'ENABLED (' + params.grm_method + ')' : 'disabled'}")
  println("Association Analysis: ${params.run_association_analysis ? 'ENABLED (' + params.association_method + ')' : 'disabled'}")
  println("Heritability Estimation: ${params.run_heritability_estimation ? 'ENABLED (' + params.heritability_method + (params.use_precomputed_grm ? ' with pre-computed GRM' : '') + ')' : 'disabled'}")
  println("Genetic Correlation: ${params.run_genetic_correlation ? 'ENABLED (' + params.genetic_correlation_method + ')' : 'disabled'}")
  println("==============================\n")

  def ANSI_RESET = "\u001B[0m"
  def ANSI_YELLOW = "\u001B[33m"
  def ANSI_GREEN = "\u001B[32m"

  // Handle deprecated parameters
  def genotypes_association_vcf = params.genotypes_association_vcf
  if (params.genotypes_imputed) {
    genotypes_association_vcf = params.genotypes_imputed
    println(ANSI_YELLOW + "WARN: Option genotypes_imputed is deprecated. Please use genotypes_association_vcf instead." + ANSI_RESET)
  }
  if (params.genotypes_association) {
    genotypes_association_vcf = params.genotypes_association
    println(ANSI_YELLOW + "WARN: Option genotypes_association is deprecated. Please use genotypes_association_vcf instead." + ANSI_RESET)
  }

  def genotypes_prediction = params.genotypes_prediction
  if (params.genotypes_array) {
    genotypes_prediction = params.genotypes_array
    println(ANSI_YELLOW + "WARN: Option genotypes_array is deprecated. Please use genotypes_prediction instead." + ANSI_RESET)
  }

  // =============================================================================
  // COMMON DATA PREPARATION
  // =============================================================================

  // Use Ternary File pattern: phenotypes not required for GRM-only mode or summary statistics methods
  // Summary statistics methods (ldak_sumher, ldak_sumcors) don't need phenotype files
  def needs_phenotypes = params.run_association_analysis ||
                         (params.run_heritability_estimation && params.heritability_method != 'ldak_sumher') ||
                         (params.run_genetic_correlation && params.genetic_correlation_method != 'ldak_sumcors')

  phenotypes_file = needs_phenotypes
      ? file(params.phenotypes_filename, checkIfExists: true)
      : []

  // Use Ternary File pattern: file object if provided, empty list [] if not
  covariates_file = params.covariates_filename ? file(params.covariates_filename, checkIfExists: true) : []

  // Prepare genotyped PLINK channel for prediction-based methods
  genotyped_plink_ch = Channel.empty()
  if (!params.regenie_skip_predictions && params.run_association_analysis) {
    genotyped_plink_ch = Channel.fromFilePairs(genotypes_prediction, size: 3, checkIfExists: true)
  } else if (params.run_heritability_estimation && params.heritability_method in ['gcta_greml', 'gcta_greml_ldms', 'ldak_reml', 'ldak_he', 'ldak_pcgc', 'ldak_qc']) {
    // Heritability methods also need prediction genotypes (which are actually the analysis genotypes for heritability)
    genotyped_plink_ch = Channel.fromFilePairs(genotypes_prediction, size: 3, checkIfExists: true)
  } else if (params.run_genetic_correlation && params.genetic_correlation_method in ['gcta_bivariate_greml', 'gcta_bivariate_greml_ldms']) {
    // GCTA bivariate methods need PLINK files for GRM calculation
    genotyped_plink_ch = Channel.fromFilePairs(genotypes_prediction, size: 3, checkIfExists: true)
  }

  // Optional condition-list file for REGENIE
  condition_list_file = Channel.empty()
  if (params.regenie_condition_list && params.run_association_analysis) {
    condition_list_file = Channel.fromPath(params.regenie_condition_list)
  }

  // =============================================================================
  // GENOTYPE FORMAT HANDLING
  // =============================================================================
  // Three input parameters supported (users can supply any combination):
  //   - genotypes_association_vcf:    VCF files (converted to PLINK1/PLINK2 if needed)
  //   - genotypes_association_plink1: PLINK1 files (bed/bim/fam) - used directly
  //   - genotypes_association_plink2: PLINK2 files (pgen/psam/pvar) - used directly
  //
  // Conversion logic:
  //   - If PLINK1 supplied: use directly, skip VCF→PLINK1 conversion
  //   - If PLINK2 supplied: use directly, skip VCF→PLINK2 conversion
  //   - If neither supplied but VCF provided: convert VCF to needed format(s)
  //   - If both PLINK1 and PLINK2 supplied: no conversions needed
  // =============================================================================

  imputed_plink2_ch = Channel.empty()
  imputed_plink_ch = Channel.empty()

  // Genotype data is required for most workflows except summary statistics methods
  // ldak_sumher uses summary statistics only (no individual-level genotypes needed)
  // ldak_sumcors is already correctly excluded via the genetic_correlation_method check
  def needs_genotypes = params.run_grm_only ||
                        params.run_association_analysis ||
                        (params.run_heritability_estimation && params.heritability_method != 'ldak_sumher') ||
                        (params.run_genetic_correlation && params.genetic_correlation_method in ['gcta_bivariate_greml', 'gcta_bivariate_greml_ldms'])

  if (needs_genotypes) {

    // Determine which formats are provided
    def has_vcf = genotypes_association_vcf != null
    def has_plink1 = params.genotypes_association_plink1 != null
    def has_plink2 = params.genotypes_association_plink2 != null

    // Validate at least one input is provided
    if (!has_vcf && !has_plink1 && !has_plink2) {
      error("No genotype files provided. Please specify at least one of: genotypes_association_vcf, genotypes_association_plink1, or genotypes_association_plink2")
    }

    // Print input format summary
    println(ANSI_GREEN + "=== Genotype Input ===" + ANSI_RESET)
    if (has_vcf) println(ANSI_GREEN + "  VCF files: ${genotypes_association_vcf}" + ANSI_RESET)
    if (has_plink1) println(ANSI_GREEN + "  PLINK1 files: ${params.genotypes_association_plink1}" + ANSI_RESET)
    if (has_plink2) println(ANSI_GREEN + "  PLINK2 files: ${params.genotypes_association_plink2}" + ANSI_RESET)

    // --------------------------------------------------------------------------
    // STEP 1: Load user-supplied PLINK1 files (if provided)
    // --------------------------------------------------------------------------
    if (has_plink1) {
      println(ANSI_GREEN + "  → Using supplied PLINK1 files directly" + ANSI_RESET)

      // Custom key extraction to handle filenames with multiple dots (e.g., chr01.vcf.bed)
      // By default, fromFilePairs uses simple basename extraction which fails for such patterns
      imputed_plink_ch = Channel.fromFilePairs(params.genotypes_association_plink1, size: 3, checkIfExists: true) { file ->
          file.name.replaceAll(/\.(bed|bim|fam)$/, '')
        }
        .toList()
        .flatMap { pairs ->
          // Validate filenames contain double digit numbers
          def invalid_files = pairs.findAll { name, files -> !(name =~ /\d{2}/) }
          if (invalid_files) {
            error("PLINK1 files without double digit numbers found: ${invalid_files.collect { it[0] }.join(', ')}")
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
      imputed_plink2_ch = Channel.fromFilePairs(params.genotypes_association_plink2, size: 3, checkIfExists: true) { file ->
          file.name.replaceAll(/\.(pgen|psam|pvar)$/, '')
        }
        .toList()
        .flatMap { pairs ->
          // Validate filenames contain double digit numbers
          def invalid_files = pairs.findAll { name, files -> !(name =~ /\d{2}/) }
          if (invalid_files) {
            error("PLINK2 files without double digit numbers found: ${invalid_files.collect { it[0] }.join(', ')}")
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
      imputed_files_ch = channel.fromPath(genotypes_association_vcf, checkIfExists: true)
        .toList()
        .flatMap { files ->
          def invalid_files = files.findAll { file -> !(file.name =~ /\d{2}/) }
          if (invalid_files) {
            error("VCF files without double digit numbers found: ${invalid_files.collect { it.name }.join(', ')}")
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

  // Define genotypes association format (now 'bed' for PLINK1 format used by REGENIE)
  def genotypes_association_format = 'bed'

  // =============================================================================
  // 0. GRM-ONLY COMPUTATION MODE
  // =============================================================================
  // This mode computes GRM without running any downstream analysis.
  // Output GRM files can be used with --use_precomputed_grm in subsequent runs.
  grm_only_results = Channel.empty()

  if (params.run_grm_only) {
    println(ANSI_GREEN + "▶ Running GRM-Only Computation: ${params.grm_method}" + ANSI_RESET)

    if (params.grm_method == 'gcta') {
      // Standard GCTA GRM (optionally with sparse GRM for FastGWA)
      GCTA_GRM(
        imputed_plink2_ch,
        params.nparts_gcta,
        Channel.of(["0", []]),  // No SNP extraction (snp_group="0", snp_file=[])
        params.gcta_create_sparse_grm,
        params.gcta_sparse_cutoff,
        false  // skip_relatedness_filter
      )
      grm_only_results = GCTA_GRM.out.grm_files

    } else if (params.grm_method == 'gcta_ldms') {
      // GCTA GRM with LD stratification (4 SNP groups by MAF/LD)
      GCTA_GRM_LDMS(
        imputed_plink2_ch,
        imputed_plink_ch,
        params.nparts_gcta
      )
      grm_only_results = GCTA_GRM_LDMS.out.grm_files

    } else if (params.grm_method == 'ldak') {
      // LDAK kinship matrices
      // Note: LDAK_GRM only computes and filters kinships; adjustment is done in analysis workflows
      LDAK_GRM(
        imputed_plink_ch,
        params.heritability_model
      )
      grm_only_results = LDAK_GRM.out.combined_grm

    } else {
      error("Unknown grm_method: ${params.grm_method}. Valid options: 'gcta', 'gcta_ldms', 'ldak'")
    }
  }

  // =============================================================================
  // 1. ASSOCIATION ANALYSIS
  // =============================================================================
  if (params.run_association_analysis) {
    println(ANSI_GREEN + "▶ Running Association Analysis: ${params.association_method}" + ANSI_RESET)

    if (params.association_method == 'regenie') {
      SINGLE_VARIANT_TESTS(
        imputed_plink_ch,
        phenotypes_file,
        covariates_file,
        genotyped_plink_ch,
        params.genotypes_build,
        genotypes_association_format,
        condition_list_file,
        params.regenie_skip_predictions
      )
    } else if (params.association_method == 'fastgwa') {
      GCTA_FASTGWA(
        imputed_plink2_ch,
        phenotypes_file,
        covariates_file,
        params.nparts_gcta,
        0.05  // sparse_cutoff (default)
      )
    } else {
      error("Unknown association_method: ${params.association_method}. Valid options: 'regenie', 'fastgwa'")
    }
  }

  // =============================================================================
  // 2. HERITABILITY ESTIMATION
  // =============================================================================
  if (params.run_heritability_estimation) {
    println(ANSI_GREEN + "▶ Running Heritability Estimation: ${params.heritability_method}" + ANSI_RESET)

    // --------------------------------------------------------------------------
    // MODE A: Pre-computed GRM (use *_ANALYSIS workflows)
    // --------------------------------------------------------------------------
    if (params.use_precomputed_grm) {
      println(ANSI_GREEN + "  Using pre-computed GRM files" + ANSI_RESET)

      // GCTA GREML with pre-computed GRM
      if (params.heritability_method == 'gcta_greml') {
        if (!params.gcta_grm_prefix) {
          error("GCTA GREML with pre-computed GRM requires --gcta_grm_prefix parameter")
        }
        // Load GRM files from prefix
        grm_files_ch = Channel.of(tuple(
          "0",  // snp_group (single group for standard GREML)
          params.gcta_grm_prefix,
          file("${params.gcta_grm_prefix}.grm.id", checkIfExists: true),
          file("${params.gcta_grm_prefix}.grm.bin", checkIfExists: true),
          file("${params.gcta_grm_prefix}.grm.N.bin", checkIfExists: true)
        ))

        GCTA_REML_ANALYSIS(
          grm_files_ch,
          phenotypes_file,
          covariates_file
        )
      }
      // GCTA GREML-LDMS with pre-computed multi-GRM
      else if (params.heritability_method == 'gcta_greml_ldms') {
        if (!params.gcta_mgrm_file) {
          error("GCTA GREML-LDMS with pre-computed GRM requires --gcta_mgrm_file parameter")
        }
        // Load mgrm file which contains paths to all GRM prefixes
        mgrm_file = file(params.gcta_mgrm_file, checkIfExists: true)
        // Get the directory containing the mgrm file (GRM files should be in same directory)
        def mgrm_dir = mgrm_file.parent

        // Read prefixes from mgrm file and collect all GRM files
        // Each line in mgrm file is a GRM prefix (just the name, not full path)
        // Look for GRM files in the same directory as the mgrm file
        all_grm_files_ch = Channel.fromPath(params.gcta_mgrm_file)
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

        GCTA_REML_LDMS_ANALYSIS(
          mgrm_file,
          all_grm_files_ch,
          phenotypes_file,
          covariates_file
        )
      }
      // LDAK REML with pre-computed GRM
      else if (params.heritability_method == 'ldak_reml') {
        if (!params.ldak_grm_prefix) {
          error("LDAK REML with pre-computed GRM requires --ldak_grm_prefix parameter")
        }
        // Load combined GRM files
        combined_grm_ch = Channel.of(tuple(
          params.ldak_grm_prefix,
          file("${params.ldak_grm_prefix}.grm.bin", checkIfExists: true),
          file("${params.ldak_grm_prefix}.grm.id", checkIfExists: true),
          file("${params.ldak_grm_prefix}.grm.details", checkIfExists: true),
          file("${params.ldak_grm_prefix}.grm.adjust", checkIfExists: true)
        ))
        // Load filtered.keep file (always at {prefix}.keep, output by LDAK_GRM)
        filtered_list = file("${params.ldak_grm_prefix}.keep", checkIfExists: true)

        LDAK_REML_ANALYSIS(
          combined_grm_ch,
          filtered_list,
          phenotypes_file,
          covariates_file
        )
      }
      // LDAK HE with pre-computed GRM
      else if (params.heritability_method == 'ldak_he') {
        // Need either adjusted GRM or non-adjusted GRM
        if (!params.ldak_grm_prefix && !params.ldak_adjusted_grm_prefix) {
          error("LDAK HE with pre-computed GRM requires --ldak_grm_prefix or --ldak_adjusted_grm_prefix parameter")
        }

        // Determine GRM prefix and load files
        def grm_prefix = params.ldak_adjusted_grm_prefix ?: params.ldak_grm_prefix

        // Load filtered.keep file (always at {prefix}.keep, output by LDAK_GRM)
        filtered_list = file("${grm_prefix}.keep", checkIfExists: true)

        // Load GRM - workflow will detect if adjustment is needed based on tuple size
        if (params.ldak_adjusted_grm_prefix) {
          // Pre-adjusted GRM (6-element tuple)
          grm_ch = Channel.of(tuple(
            params.ldak_adjusted_grm_prefix,
            file("${params.ldak_adjusted_grm_prefix}.grm.bin", checkIfExists: true),
            file("${params.ldak_adjusted_grm_prefix}.grm.id", checkIfExists: true),
            file("${params.ldak_adjusted_grm_prefix}.grm.details", checkIfExists: true),
            file("${params.ldak_adjusted_grm_prefix}.grm.adjust", checkIfExists: true),
            file("${params.ldak_adjusted_grm_prefix}.grm.root", checkIfExists: true)
          ))
        } else {
          // Non-adjusted GRM (5-element tuple) - workflow will compute adjustment
          grm_ch = Channel.of(tuple(
            params.ldak_grm_prefix,
            file("${params.ldak_grm_prefix}.grm.bin", checkIfExists: true),
            file("${params.ldak_grm_prefix}.grm.id", checkIfExists: true),
            file("${params.ldak_grm_prefix}.grm.details", checkIfExists: true),
            file("${params.ldak_grm_prefix}.grm.adjust", checkIfExists: true)
          ))
        }

        LDAK_HE_ANALYSIS(
          grm_ch,
          filtered_list,
          phenotypes_file,
          covariates_file
        )
      }
      // LDAK PCGC with pre-computed GRM
      else if (params.heritability_method == 'ldak_pcgc') {
        if (params.ldak_pcgc_prevalence == null) {
          error("LDAK PCGC requires --ldak_pcgc_prevalence parameter (disease prevalence, e.g., 0.05)")
        }
        // Need either adjusted GRM or non-adjusted GRM
        if (!params.ldak_grm_prefix && !params.ldak_adjusted_grm_prefix) {
          error("LDAK PCGC with pre-computed GRM requires --ldak_grm_prefix or --ldak_adjusted_grm_prefix parameter")
        }

        // Determine GRM prefix and load files
        def grm_prefix = params.ldak_adjusted_grm_prefix ?: params.ldak_grm_prefix

        // Load filtered.keep file (always at {prefix}.keep, output by LDAK_GRM)
        filtered_list = file("${grm_prefix}.keep", checkIfExists: true)

        // Load GRM - workflow will detect if adjustment is needed based on tuple size
        if (params.ldak_adjusted_grm_prefix) {
          // Pre-adjusted GRM (6-element tuple)
          grm_ch = Channel.of(tuple(
            params.ldak_adjusted_grm_prefix,
            file("${params.ldak_adjusted_grm_prefix}.grm.bin", checkIfExists: true),
            file("${params.ldak_adjusted_grm_prefix}.grm.id", checkIfExists: true),
            file("${params.ldak_adjusted_grm_prefix}.grm.details", checkIfExists: true),
            file("${params.ldak_adjusted_grm_prefix}.grm.adjust", checkIfExists: true),
            file("${params.ldak_adjusted_grm_prefix}.grm.root", checkIfExists: true)
          ))
        } else {
          // Non-adjusted GRM (5-element tuple) - workflow will compute adjustment
          grm_ch = Channel.of(tuple(
            params.ldak_grm_prefix,
            file("${params.ldak_grm_prefix}.grm.bin", checkIfExists: true),
            file("${params.ldak_grm_prefix}.grm.id", checkIfExists: true),
            file("${params.ldak_grm_prefix}.grm.details", checkIfExists: true),
            file("${params.ldak_grm_prefix}.grm.adjust", checkIfExists: true)
          ))
        }

        LDAK_PCGC_ANALYSIS(
          grm_ch,
          filtered_list,
          phenotypes_file,
          covariates_file
        )
      }
      // Methods not supporting pre-computed GRM
      else if (params.heritability_method in ['bolt_lmm_reml', 'ldak_qc', 'ldak_sumher']) {
        error("Method '${params.heritability_method}' does not support pre-computed GRM. Use without --use_precomputed_grm")
      }
      else {
        error("Unknown heritability_method: ${params.heritability_method}")
      }
    }

    // --------------------------------------------------------------------------
    // MODE B: Auto-compute GRM (standard workflows)
    // --------------------------------------------------------------------------
    else {
      // GCTA methods
      if (params.heritability_method == 'gcta_greml') {
        GCTA_GREML(
          phenotypes_file,
          covariates_file,
          imputed_plink2_ch,
          params.nparts_gcta
        )
      } else if (params.heritability_method == 'gcta_greml_ldms') {
        GCTA_GREML_LDMS(
          phenotypes_file,
          covariates_file,
          imputed_plink2_ch,
          imputed_plink_ch,
          params.nparts_gcta
        )
      }

      // BOLT-LMM methods
      else if (params.heritability_method == 'bolt_lmm_reml') {
        BOLT_LMM_REML(
          imputed_plink_ch,
          phenotypes_file,
          covariates_file
        )
      }

      // LDAK individual-level methods
      else if (params.heritability_method == 'ldak_reml') {
        LDAK_REML_WORKFLOW(
          imputed_plink_ch,
          phenotypes_file,
          covariates_file,
          params.heritability_model
        )
      } else if (params.heritability_method == 'ldak_he') {
        LDAK_HE_WORKFLOW(
          imputed_plink_ch,
          phenotypes_file,
          covariates_file,
          params.heritability_model
        )
      } else if (params.heritability_method == 'ldak_pcgc') {
        if (params.ldak_pcgc_prevalence == null) {
          error("LDAK PCGC requires --ldak_pcgc_prevalence parameter (disease prevalence, e.g., 0.05)")
        }
        LDAK_PCGC_WORKFLOW(
          imputed_plink_ch,
          phenotypes_file,
          covariates_file,
          params.heritability_model
        )
      } else if (params.heritability_method == 'ldak_qc') {
        LDAK_QC(
          imputed_plink_ch,
          phenotypes_file,
          covariates_file
        )
      }

      // LDAK summary statistics method
      else if (params.heritability_method == 'ldak_sumher') {
        if (params.ldak_sumher_tagfile == null || params.ldak_sumher_summary_stats == null) {
          error("LDAK SumHer requires --ldak_sumher_tagfile and --ldak_sumher_summary_stats parameters")
        }

        summary_stats_ch = Channel.fromPath(params.ldak_sumher_summary_stats)
          .map { file ->
            def trait_name = file.baseName.replaceAll(/\..*/, '')
            return tuple(trait_name, file)
          }

        LDAK_SUMHER_WORKFLOW(
          summary_stats_ch,
          file(params.ldak_sumher_tagfile)
        )
      }

      else {
        error("Unknown heritability_method: ${params.heritability_method}. Valid options: 'gcta_greml', 'gcta_greml_ldms', 'bolt_lmm_reml', 'ldak_reml', 'ldak_he', 'ldak_pcgc', 'ldak_qc', 'ldak_sumher'")
      }
    }
  }

  // =============================================================================
  // 3. GENETIC CORRELATION
  // =============================================================================
  if (params.run_genetic_correlation) {
    println(ANSI_GREEN + "▶ Running Genetic Correlation: ${params.genetic_correlation_method}" + ANSI_RESET)

    if (params.genetic_correlation_method == 'ldak_sumcors') {
      if (params.ldak_sumcors_tagfile == null || params.ldak_sumcors_summary_stats1 == null || params.ldak_sumcors_summary_stats2 == null) {
        error("LDAK SumCors requires --ldak_sumcors_tagfile, --ldak_sumcors_summary_stats1, and --ldak_sumcors_summary_stats2 parameters")
      }

      summary_stats1_file = file(params.ldak_sumcors_summary_stats1)
      summary_stats2_file = file(params.ldak_sumcors_summary_stats2)

      trait1_name = summary_stats1_file.baseName.replaceAll(/\..*/, '')
      trait2_name = summary_stats2_file.baseName.replaceAll(/\..*/, '')

      summary_stats_pairs_ch = Channel.of(
        tuple(trait1_name, summary_stats1_file, trait2_name, summary_stats2_file)
      )

      LDAK_SUMCORS_WORKFLOW(
        summary_stats_pairs_ch,
        file(params.ldak_sumcors_tagfile)
      )
    } else if (params.genetic_correlation_method == 'gcta_bivariate_greml') {
      // Validate required parameters
      if (!params.gcta_bivariate_phenotype1 || !params.gcta_bivariate_phenotype2) {
        error("GCTA bivariate GREML requires --gcta_bivariate_phenotype1 and --gcta_bivariate_phenotype2 parameters")
      }

      GCTA_BIVARIATE_GREML(
        phenotypes_file,
        covariates_file,
        imputed_plink2_ch,
        params.nparts_gcta,
        params.gcta_bivariate_phenotype1,
        params.gcta_bivariate_phenotype2
      )
    } else if (params.genetic_correlation_method == 'gcta_bivariate_greml_ldms') {
      // Validate required parameters
      if (!params.gcta_bivariate_phenotype1 || !params.gcta_bivariate_phenotype2) {
        error("GCTA bivariate GREML-LDMS requires --gcta_bivariate_phenotype1 and --gcta_bivariate_phenotype2 parameters")
      }

      GCTA_BIVARIATE_GREML_LDMS(
        phenotypes_file,
        covariates_file,
        imputed_plink2_ch,
        imputed_plink_ch,
        params.nparts_gcta,
        params.gcta_bivariate_phenotype1,
        params.gcta_bivariate_phenotype2
      )
    } else {
      error("Unknown genetic_correlation_method: ${params.genetic_correlation_method}. Valid options: 'ldak_sumcors', 'gcta_bivariate_greml', 'gcta_bivariate_greml_ldms'")
    }
  }

  // =============================================================================
  // OUTPUT EMISSIONS
  // =============================================================================
  emit:
  // GRM-Only computation outputs
  grm_results = grm_only_results

  // Association Analysis outputs (conditional)
  association_results = params.run_association_analysis && params.association_method == 'regenie' ?
    SINGLE_VARIANT_TESTS.out.regenie_step2_results :
    Channel.empty()

  // Heritability Estimation outputs (conditional)
  heritability_results = params.run_heritability_estimation && params.heritability_method == 'ldak_qc' ?
    LDAK_QC.out.quarter_reml_results :
    Channel.empty()

  heritability_inflation = params.run_heritability_estimation && params.heritability_method == 'ldak_qc' ?
    LDAK_QC.out.inflation_results :
    Channel.empty()

  // Genetic Correlation outputs (conditional)
  genetic_correlation_results = params.run_genetic_correlation ?
    (params.genetic_correlation_method == 'ldak_sumcors' ?
      LDAK_SUMCORS_WORKFLOW.out.correlation_results :
      (params.genetic_correlation_method == 'gcta_bivariate_greml' ?
        GCTA_BIVARIATE_GREML.out.bivariate_results :
        (params.genetic_correlation_method == 'gcta_bivariate_greml_ldms' ?
          GCTA_BIVARIATE_GREML_LDMS.out.bivariate_results :
          Channel.empty()))) :
    Channel.empty()
}
