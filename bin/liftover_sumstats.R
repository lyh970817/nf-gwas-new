#!/usr/bin/env Rscript

# Liftover GWAS summary statistics between genome builds
# Usage: liftover_sumstats.R <input_file> <output_file> <target_build> [source_build] [frq_filter]
#
# Converts GWAS summary statistics from one genome build to another using
# MungeSumstats::liftover(). The source build can be auto-detected if not specified.
#
# Arguments:
#   input_file   - Input summary statistics file (tsv/csv/gz)
#   output_file  - Output file path (will be gzipped if ends with .gz)
#   target_build - Target genome build: "GRCh37" or "GRCh38"
#   source_build - (Optional) Source genome build: "GRCh37", "GRCh38", or "auto"
#   frq_filter   - (Optional) MAF filter threshold (default: 0.01). Removes variants
#                  with FRQ < frq_filter OR FRQ > (1 - frq_filter)
#
# Required R packages:
#   - MungeSumstats (Bioconductor)
#   - data.table
#
# Note: MungeSumstats requires chain files from rtracklayer for liftover.
# These are automatically downloaded on first use.

suppressPackageStartupMessages({
    library(data.table)
    library(MungeSumstats)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
    stop("Usage: liftover_sumstats.R <input_file> <output_file> <target_build> [source_build] [frq_filter]")
}

input_file <- args[1]
output_file <- args[2]
target_build <- args[3]
source_build <- if (length(args) >= 4) args[4] else "auto"
frq_filter <- if (length(args) >= 5) as.numeric(args[5]) else 0.01

# Validate target build
valid_builds <- c("GRCh37", "GRCh38")
if (!target_build %in% valid_builds) {
    stop(sprintf("Invalid target build: %s. Must be one of: %s",
                 target_build, paste(valid_builds, collapse = ", ")))
}

# Validate FRQ filter
if (is.na(frq_filter) || frq_filter < 0 || frq_filter >= 0.5) {
    stop(sprintf("Invalid FRQ filter: %s. Must be a number between 0 and 0.5", args[5]))
}

# Check input file
if (!file.exists(input_file)) {
    stop(sprintf("Input file not found: %s", input_file))
}

cat(sprintf("Input file: %s\n", input_file))
cat(sprintf("Output file: %s\n", output_file))
cat(sprintf("Target build: %s\n", target_build))
cat(sprintf("Source build: %s\n", source_build))
cat(sprintf("FRQ filter: %.4f (removes MAF < %.4f)\n", frq_filter, frq_filter))

tryCatch({
    # Read input file
    cat("Reading input file...\n")
    sumstats_dt <- fread(input_file, header = TRUE)
    n_initial <- nrow(sumstats_dt)
    cat(sprintf("Read %d variants\n", n_initial))

    # Detect or validate source build
    if (tolower(source_build) == "auto") {
        cat("Auto-detecting source genome build...\n")
        # MungeSumstats can infer the genome build
        # We'll let liftover handle it by passing NULL for ref_genome
        ref_genome <- NULL
    } else if (source_build %in% valid_builds) {
        ref_genome <- source_build
    } else {
        stop(sprintf("Invalid source build: %s. Must be one of: %s, auto",
                     source_build, paste(valid_builds, collapse = ", ")))
    }

    # Standardize column names for MungeSumstats
    # Common column name mappings
    col_mapping <- list(
        # Chromosome
        CHR = c("CHROM", "CHR", "chr", "chromosome", "#CHROM"),
        # Position
        BP = c("GENPOS", "BP", "POS", "pos", "position", "bp"),
        # SNP ID
        SNP = c("ID", "SNP", "rsid", "rsID", "RSID", "MarkerName", "Predictor"),
        # Effect allele
        A1 = c("ALLELE1", "A1", "ALT", "effect_allele", "EffectAllele", "EA"),
        # Other allele
        A2 = c("ALLELE0", "A2", "REF", "other_allele", "OtherAllele", "NEA"),
        # Effect size
        BETA = c("BETA", "beta", "Effect", "effect", "B"),
        # Standard error
        SE = c("SE", "se", "StdErr", "stderr"),
        # P-value
        P = c("P", "p", "pvalue", "p.value", "P.value", "PVALUE", "Pvalue"),
        # Sample size
        N = c("N", "n", "NMISS", "TotalSampleSize"),
        # Frequency
        FRQ = c("A1FREQ", "FRQ", "freq", "MAF", "EAF", "AF", "Frequency")
    )

    # Apply standardization
    current_names <- names(sumstats_dt)
    for (standard_name in names(col_mapping)) {
        for (alt_name in col_mapping[[standard_name]]) {
            if (alt_name %in% current_names && !(standard_name %in% current_names)) {
                setnames(sumstats_dt, alt_name, standard_name)
                cat(sprintf("Renamed column: %s -> %s\n", alt_name, standard_name))
                break
            }
        }
    }

    # Handle LOG10P -> P conversion if needed
    if ("LOG10P" %in% names(sumstats_dt) && !("P" %in% names(sumstats_dt))) {
        sumstats_dt[, P := 10^(-LOG10P)]
        cat("Converted LOG10P to P-value\n")
    }

    # Apply FRQ filter BEFORE liftover to reduce computation
    if ("FRQ" %in% names(sumstats_dt) && frq_filter > 0) {
        n_before_frq <- nrow(sumstats_dt)

        # Filter: keep variants where MAF >= frq_filter
        # MAF is min(FRQ, 1-FRQ), so we filter:
        # FRQ >= frq_filter AND FRQ <= (1 - frq_filter)
        sumstats_dt <- sumstats_dt[FRQ >= frq_filter & FRQ <= (1 - frq_filter)]

        n_after_frq <- nrow(sumstats_dt)
        n_removed_frq <- n_before_frq - n_after_frq
        pct_removed_frq <- 100 * n_removed_frq / n_before_frq

        cat(sprintf("FRQ filter applied: removed %d variants (%.2f%%) with MAF < %.4f\n",
                    n_removed_frq, pct_removed_frq, frq_filter))
        cat(sprintf("Variants remaining after FRQ filter: %d\n", n_after_frq))
    } else if (!("FRQ" %in% names(sumstats_dt))) {
        cat("Warning: No FRQ/MAF column found - skipping frequency filter\n")
    }

    # Check if conversion is needed
    if (!is.null(ref_genome) && ref_genome == target_build) {
        cat("Source and target builds are the same. No liftover needed.\n")
        result <- sumstats_dt
    } else {
        # Perform liftover
        n_before_liftover <- nrow(sumstats_dt)
        cat(sprintf("Performing liftover to %s...\n", target_build))

        result <- liftover(
            sumstats_dt = sumstats_dt,
            ref_genome = ref_genome,
            convert_ref_genome = target_build,
            chain_source = "ensembl",
            imputation_ind = FALSE,
            chrom_col = "CHR",
            start_col = "BP",
            as_granges = FALSE,
            style = "NCBI",
            verbose = TRUE
        )

        n_after_liftover <- nrow(result)
        n_lost_liftover <- n_before_liftover - n_after_liftover
        pct_lost_liftover <- 100 * n_lost_liftover / n_before_liftover

        cat(sprintf("Variants lost during liftover: %d (%.2f%%)\n", n_lost_liftover, pct_lost_liftover))

        if (pct_lost_liftover > 10) {
            warning(sprintf("Warning: %.1f%% of variants were lost during liftover. This may indicate issues with the input data or coordinate mapping.", pct_lost_liftover))
        }
    }

    # Final summary statistics
    n_final <- nrow(result)
    n_total_removed <- n_initial - n_final
    pct_total_removed <- 100 * n_total_removed / n_initial

    cat("\n=== Processing Summary ===\n")
    cat(sprintf("Initial variants: %d\n", n_initial))
    cat(sprintf("Final variants: %d\n", n_final))
    cat(sprintf("Total removed: %d (%.2f%%)\n", n_total_removed, pct_total_removed))
    cat("==========================\n\n")

    # Write output
    output_dir <- dirname(output_file)
    if (output_dir != "." && !dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }

    if (grepl("\\.gz$", output_file)) {
        fwrite(result, output_file, sep = "\t", quote = FALSE, compress = "gzip")
    } else {
        fwrite(result, output_file, sep = "\t", quote = FALSE)
    }

    cat(sprintf("Successfully wrote lifted summary statistics to: %s\n", output_file))
    cat(sprintf("Final variant count: %d\n", nrow(result)))
    cat(sprintf("Columns: %s\n", paste(names(result), collapse = ", ")))

}, error = function(e) {
    cat("ERROR during liftover:\n", file = stderr())
    cat(e$message, "\n", file = stderr())
    quit(status = 1)
})
