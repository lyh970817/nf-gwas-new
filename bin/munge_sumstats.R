#!/usr/bin/env Rscript

# Summary statistics standardization for GWAS results
# Usage: munge_sumstats.R <input_file> <output_file> <genome_build> [dbsnp_version]
#
# When dbsnp_version is 0 or "none":
#   - Performs manual column standardization (faster, no dependencies)
#   - Converts REGENIE format to standard GWAS format
#
# When dbsnp_version is set (e.g., 155):
#   - Uses MungeSumstats with full dbSNP annotation
#   - Requires SNPlocs.Hsapiens.dbSNP<version>.<genome_build> package

suppressPackageStartupMessages({
    library(data.table)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
    stop("Usage: munge_sumstats.R <input_file> <output_file> <genome_build> [dbsnp_version]")
}

input_file <- args[1]
output_file <- args[2]
genome_build <- args[3]
dbsnp_version <- if (length(args) >= 4) args[4] else "0"

# Check if dbSNP annotation is disabled
use_dbsnp <- !(dbsnp_version == "0" || tolower(dbsnp_version) == "none")

if (use_dbsnp) {
    dbsnp_int <- as.integer(dbsnp_version)
    cat(sprintf("dbSNP version: %d (requires SNPlocs package)\n", dbsnp_int))
} else {
    cat("dbSNP annotation: DISABLED (using manual standardization)\n")
}

# Validate genome build
valid_builds <- c("GRCh37", "GRCh38")
if (!genome_build %in% valid_builds) {
    stop(sprintf("Invalid genome build: %s. Must be one of: %s",
                 genome_build, paste(valid_builds, collapse = ", ")))
}

cat(sprintf("Input file: %s\n", input_file))
cat(sprintf("Output file: %s\n", output_file))
cat(sprintf("Genome build: %s\n", genome_build))

# Check if input file exists
if (!file.exists(input_file)) {
    stop(sprintf("Input file not found: %s", input_file))
}

# Function to standardize REGENIE output manually
standardize_regenie_manual <- function(input_path) {
    cat("Reading input file...\n")
    dt <- fread(input_path, header = TRUE)
    cat(sprintf("Read %d variants\n", nrow(dt)))

    # REGENIE column mapping to standard format
    # REGENIE columns: CHROM, GENPOS, ID, ALLELE0, ALLELE1, A1FREQ, N, TEST, BETA, SE, CHISQ, LOG10P, EXTRA
    # Standard columns: CHR, BP, SNP, A1, A2, FRQ, N, BETA, SE, P, Z

    # Rename columns
    col_mapping <- c(
        "CHROM" = "CHR",
        "GENPOS" = "BP",
        "ID" = "SNP",
        "ALLELE1" = "A1",  # REGENIE: ALLELE1 is tested (effect) allele
        "ALLELE0" = "A2",  # REGENIE: ALLELE0 is other allele
        "A1FREQ" = "FRQ"
    )

    for (old_name in names(col_mapping)) {
        if (old_name %in% names(dt)) {
            new_name <- col_mapping[old_name]
            setnames(dt, old_name, new_name)
        }
    }

    # Convert LOG10P to P-value
    # REGENIE LOG10P is -log10(p), so P = 10^(-LOG10P)
    if ("LOG10P" %in% names(dt)) {
        dt[, P := 10^(-LOG10P)]
        dt[, LOG10P := NULL]
    }

    # Calculate Z-score if not present
    if (!("Z" %in% names(dt)) && all(c("BETA", "SE") %in% names(dt))) {
        dt[, Z := BETA / SE]
    }

    # Remove unnecessary columns
    cols_to_keep <- c("CHR", "BP", "SNP", "A1", "A2", "FRQ", "N", "BETA", "SE", "P", "Z")
    cols_available <- intersect(cols_to_keep, names(dt))
    dt <- dt[, ..cols_available]

    # Remove rows with missing essential values
    essential_cols <- c("CHR", "BP", "A1", "A2")
    for (col in essential_cols) {
        if (col %in% names(dt)) {
            dt <- dt[!is.na(get(col))]
        }
    }

    # Remove sex and mitochondrial chromosomes
    if ("CHR" %in% names(dt)) {
        dt <- dt[!CHR %in% c("X", "Y", "MT", "chrX", "chrY", "chrMT", 23, 24, 25)]
    }

    # Convert chromosome to integer if possible (remove "chr" prefix)
    if ("CHR" %in% names(dt)) {
        dt[, CHR := gsub("^chr", "", CHR, ignore.case = TRUE)]
        # Try to convert to integer
        tryCatch({
            dt[, CHR := as.integer(CHR)]
        }, warning = function(w) {
            # Keep as character if conversion fails
        })
    }

    # Sort by chromosome and position
    if (all(c("CHR", "BP") %in% names(dt))) {
        setorder(dt, CHR, BP)
    }

    cat(sprintf("After standardization: %d variants\n", nrow(dt)))
    return(dt)
}

# Main processing
tryCatch({
    if (use_dbsnp) {
        # Use MungeSumstats with dbSNP annotation
        suppressPackageStartupMessages(library(MungeSumstats))

        result <- format_sumstats(
            path = input_file,
            ref_genome = genome_build,
            dbSNP = dbsnp_int,
            return_data = TRUE,
            return_format = "data.table",
            log_folder = dirname(output_file),
            log_mungesumstats_msgs = TRUE,
            log_folder_ind = TRUE,
            INFO_filter = 0,
            N_dropNA = FALSE,
            imputation_ind = FALSE,
            bi_allelic_filter = FALSE,
            allele_flip_check = TRUE,
            allele_flip_drop = FALSE,
            allele_flip_z = TRUE,
            allele_flip_frq = TRUE,
            rmv_chr = c("X", "Y", "MT"),
            rmv_chrPrefix = TRUE,
            on_ref_genome = FALSE,
            strand_ambig_filter = FALSE,
            convert_ref_genome = NULL,
            nThread = 1
        )
    } else {
        # Manual standardization (faster, no dbSNP dependency)
        result <- standardize_regenie_manual(input_file)
    }

    # Write output
    output_dir <- dirname(output_file)
    if (output_dir != "." && !dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE)
    }

    # Determine output format based on extension
    if (grepl("\\.gz$", output_file)) {
        fwrite(result, output_file, sep = "\t", quote = FALSE, compress = "gzip")
    } else {
        fwrite(result, output_file, sep = "\t", quote = FALSE)
    }

    cat(sprintf("Successfully wrote standardized summary statistics to: %s\n", output_file))
    cat(sprintf("Total variants: %d\n", nrow(result)))
    cat(sprintf("Columns: %s\n", paste(names(result), collapse = ", ")))

}, error = function(e) {
    cat("ERROR during processing:\n", file = stderr())
    cat(e$message, "\n", file = stderr())
    quit(status = 1)
})
