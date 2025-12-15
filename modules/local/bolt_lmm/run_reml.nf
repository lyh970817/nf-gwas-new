process RUN_BOLT_REML {
  tag "bolt_reml"
  publishDir "${params.pubDir}/bolt_reml", mode: 'copy'

  input:
    path bed_plink_files
    path bim_plink_files
    path fam_plink_file
    path phenotypes_file
    path covariates_file

  output:
    path "${phenotypes_file.baseName}.bolt.reml.log", emit: log_file

  script:
  // Build a single space-separated string:
  // "--bed A.bed --bim A.bim --bed B.bed --bim B.bim …"
  def bedBimFlags = [bed_plink_files, bim_plink_files]           // List<List<File>>
       .transpose()                        // List of [bed, bim] pairs
       .collect { bed, bim ->              // zip them
         "--bed ${bed} --bim ${bim}"
       }
       .join(' ')

  // Phenotype columns → one --phenoCol per column
  def phenoCols = params.phenotypes_columns
                     .split(',')
                     .collect { "--phenoCol=${it}" }
                     .join(' ')

  // Covariates: categorical vs quantitative (handle null covariates)
  def covarCols = ""
  def qcovarCols = ""

  if (params.covariates_columns != null && params.covariates_columns != "") {
    def allCovars  = params.covariates_columns.split(',')
    def catCovars  = params.covariates_cat_columns != null ? params.covariates_cat_columns.split(',') : []

    covarCols  = catCovars
                       .collect { "--covarCol=${it}" }
                       .join(' ')
    qcovarCols = allCovars
                       .minus(catCovars)
                       .collect { "--qCovarCol=${it}" }
                       .join(' ')
  }

  def outPrefix = phenotypes_file.baseName

  // Build covariate flags only if covariates exist
  def covarFileFlag = (params.covariates_columns != null && params.covariates_columns != "") ? "--covarFile ${covariates_file}" : ""

  """
  bolt \\
    --reml \\
    ${bedBimFlags} \\
    --fam ${fam_plink_file} \\
    --phenoFile ${phenotypes_file} \\
    ${phenoCols} \\
    ${covarFileFlag} \\
    ${covarCols} \\
    ${qcovarCols} \\
    --numThreads ${task.cpus} \\
    &> ${outPrefix}.bolt.reml.log
  """
}