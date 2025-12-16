/*
========================================================================================
    LAVA Run Analysis Process
========================================================================================
    Runs LAVA local genetic correlation analysis including univariate heritability tests
    and bivariate genetic correlation tests across genomic loci.

    LAVA (Local Analysis of [co]Variant Association) estimates local genetic correlations
    between phenotypes at specific genomic regions defined by a loci file.

    Reference: Werme et al. (2022) Nature Genetics. https://doi.org/10.1038/s41588-022-01017-y
========================================================================================
*/

process LAVA_RUN_ANALYSIS {
    tag "lava_${analysis_id}"
    publishDir "${params.pubDir}/lava", mode: 'copy'
    label 'process_medium'

    input:
    val(analysis_id)               // Unique analysis identifier
    path(ref_bed)                  // Reference PLINK .bed file
    path(ref_bim)                  // Reference PLINK .bim file
    path(ref_fam)                  // Reference PLINK .fam file
    path(sumstats_files)           // Collection of summary statistics files (must match phenotype names)
    path(loci_file)                // Locus definition file
    path(sample_overlap_file)      // Sample overlap file (can be empty list [])
    val(phenotype_info)            // JSON string with phenotype metadata: [{"name":"trait1","cases":null,"controls":null,"prevalence":null,"filename":"trait1.txt"},...]
    val(univ_threshold)            // P-value threshold for univariate filtering (default: 0.05)

    output:
    path "${analysis_id}.univ.lava",  emit: univ_results
    path "${analysis_id}.bivar.lava", emit: bivar_results, optional: true
    path "${analysis_id}.lava.log",   emit: log_file

    script:
    // Extract the prefix by removing only the .bed extension (keep .vcf if present)
    def ref_prefix = ref_bed.baseName.replaceAll(/\.bed$/, '')
    def sample_overlap_r_value = sample_overlap_file ? "'${sample_overlap_file}'" : "NULL"

    """
    #!/usr/bin/env Rscript

    # Load required libraries
    library(LAVA)
    library(jsonlite)

    # Logging function
    log_file <- file("${analysis_id}.lava.log", open = "wt")
    log_msg <- function(msg) {
        timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
        cat(paste0("[", timestamp, "] ", msg, "\\n"), file = log_file)
        cat(paste0("[", timestamp, "] ", msg, "\\n"))
    }

    log_msg("Starting LAVA analysis")
    log_msg(paste("Reference prefix:", "${ref_prefix}"))
    log_msg(paste("Loci file:", "${loci_file}"))
    log_msg(paste("Univariate threshold:", ${univ_threshold}))

    # Parse phenotype metadata from JSON
    pheno_info <- fromJSON('${phenotype_info}')
    log_msg(paste("Phenotypes:", paste(pheno_info\$name, collapse = ", ")))

    # Generate input info file dynamically
    input_info <- data.frame(
        phenotype = pheno_info\$name,
        cases = ifelse(is.na(pheno_info\$cases) | pheno_info\$cases == "NA", NA, as.numeric(pheno_info\$cases)),
        controls = ifelse(is.na(pheno_info\$controls) | pheno_info\$controls == "NA", NA, as.numeric(pheno_info\$controls)),
        prevalence = ifelse(is.na(pheno_info\$prevalence) | pheno_info\$prevalence == "NA", NA, as.numeric(pheno_info\$prevalence)),
        filename = pheno_info\$filename,
        stringsAsFactors = FALSE
    )

    # Write input info file
    write.table(input_info, "input.info.txt", sep = "\\t", row.names = FALSE, quote = FALSE)
    log_msg("Generated input info file")

    # Read locus definitions
    loci <- read.loci("${loci_file}")
    n.loc <- nrow(loci)
    log_msg(paste("Loaded", n.loc, "loci"))

    # Process input data
    tryCatch({
        input <- process.input(
            input.info.file = "input.info.txt",
            sample.overlap.file = ${sample_overlap_r_value},
            ref.prefix = "${ref_prefix}",
            phenos = pheno_info\$name
        )
        log_msg("Input data processed successfully")
    }, error = function(e) {
        log_msg(paste("ERROR processing input:", e\$message))
        stop(e)
    })

    # Initialize result lists
    u <- list()
    b <- list()

    # Progress tracking
    progress <- ceiling(quantile(1:n.loc, seq(0.05, 1, 0.05)))

    # Analyze each locus
    log_msg("Starting locus-by-locus analysis")

    for (i in 1:n.loc) {
        if (i %in% progress) {
            log_msg(paste("..", names(progress[which(progress == i)])))
        }

        # Process locus
        locus <- tryCatch({
            process.locus(loci[i, ], input)
        }, error = function(e) {
            log_msg(paste("Locus", i, "error:", e\$message))
            NULL
        })

        # Log if locus processing failed
        if (is.null(locus)) {
            log_msg(paste("Locus", loci[i, "LOC"], "skipped (NULL returned - insufficient SNPs or other issue)"))
            next
        }

        log_msg(paste("Locus", locus\$id, "processed:", locus\$n.snps, "SNPs,", locus\$K, "PCs"))

        # Extract locus info for output
        loc.info <- data.frame(
            locus = locus\$id,
            chr = locus\$chr,
            start = locus\$start,
            stop = locus\$stop,
            n.snps = locus\$n.snps,
            n.pcs = locus\$K
        )

        # Run univariate and bivariate tests with threshold filtering
        loc.out <- tryCatch({
            run.univ.bivar(locus, univ.thresh = ${univ_threshold})
        }, error = function(e) {
            log_msg(paste("Analysis error at locus", i, ":", e\$message))
            list(univ = NULL, bivar = NULL)
        })

        # Store results
        if (!is.null(loc.out\$univ)) {
            u[[i]] <- cbind(loc.info, loc.out\$univ)
        }
        if (!is.null(loc.out\$bivar)) {
            b[[i]] <- cbind(loc.info, loc.out\$bivar)
        }
    }

    # Combine and save results
    log_msg("Saving results")

    # Univariate results
    univ_results <- do.call(rbind, u)
    if (!is.null(univ_results) && nrow(univ_results) > 0) {
        write.table(univ_results, "${analysis_id}.univ.lava",
                    row.names = FALSE, quote = FALSE, col.names = TRUE, sep = "\\t")
        log_msg(paste("Univariate results written:", nrow(univ_results), "rows"))
    } else {
        # Create empty file with header
        header <- "locus\\tchr\\tstart\\tstop\\tn.snps\\tn.pcs\\tphen\\th2.obs\\th2.latent\\tascertained\\tp"
        writeLines(header, "${analysis_id}.univ.lava")
        log_msg("No univariate results - empty file created")
    }

    # Bivariate results
    bivar_results <- do.call(rbind, b)
    if (!is.null(bivar_results) && nrow(bivar_results) > 0) {
        write.table(bivar_results, "${analysis_id}.bivar.lava",
                    row.names = FALSE, quote = FALSE, col.names = TRUE, sep = "\\t")
        log_msg(paste("Bivariate results written:", nrow(bivar_results), "rows"))
    } else {
        log_msg("No bivariate results (no phenotype pairs passed univariate threshold)")
    }

    log_msg("LAVA analysis completed successfully")
    close(log_file)
    """
}
