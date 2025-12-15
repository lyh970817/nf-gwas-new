#!/usr/bin/env Rscript

# prepare_bivariate_phenotypes.R
# Extract two phenotype columns for GCTA bivariate REML analysis
# Outputs phenotype file in GCTA format (no header) and mpheno indices

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if there are enough arguments
if (length(args) < 4) {
  stop("Usage: Rscript prepare_bivariate_phenotypes.R <phenotype_file> <phenotype1_name> <phenotype2_name> <output_file> [mpheno_output_file]")
}

# Parse arguments
pheno_file <- args[1]
pheno1_name <- args[2]
pheno2_name <- args[3]
output_file <- args[4]
mpheno_output_file <- if (length(args) >= 5) args[5] else "mpheno_indices.txt"

# Read the phenotype file (supports space/tab-delimited with header)
pheno <- tryCatch({
  read.table(pheno_file, header = TRUE, sep = "", stringsAsFactors = FALSE)
}, error = function(e) {
  stop(sprintf("Failed to read phenotype file '%s': %s", pheno_file, e$message))
})

# Check minimum columns (FID, IID + at least 2 phenotypes)
if (ncol(pheno) < 4) {
  stop("Phenotype file must have at least 4 columns: FID, IID, and at least 2 phenotype columns")
}

# Get column names
col_names <- colnames(pheno)
fid_col <- col_names[1]
iid_col <- col_names[2]

# Validate phenotype column 1 exists
if (!(pheno1_name %in% col_names)) {
  available_phenos <- setdiff(col_names, c(fid_col, iid_col))
  stop(sprintf("Phenotype column '%s' not found. Available phenotype columns: %s",
               pheno1_name, paste(available_phenos, collapse = ", ")))
}

# Validate phenotype column 2 exists
if (!(pheno2_name %in% col_names)) {
  available_phenos <- setdiff(col_names, c(fid_col, iid_col))
  stop(sprintf("Phenotype column '%s' not found. Available phenotype columns: %s",
               pheno2_name, paste(available_phenos, collapse = ", ")))
}

# Check that phenotype columns are different
if (pheno1_name == pheno2_name) {
  stop("Phenotype columns must be different for bivariate analysis")
}

# Extract FID, IID, and the two phenotypes
# Order: FID, IID, phenotype1, phenotype2
result <- pheno[, c(fid_col, iid_col, pheno1_name, pheno2_name), drop = FALSE]

# Replace any R NA values with -9 (GCTA missing value format)
result[is.na(result)] <- -9

# Write phenotype file without header (GCTA format)
write.table(result, output_file,
            sep = "\t",
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

cat(sprintf("Bivariate phenotype file created: %s\n", output_file))
cat(sprintf("  - Phenotype 1: %s (column 1 in output)\n", pheno1_name))
cat(sprintf("  - Phenotype 2: %s (column 2 in output)\n", pheno2_name))
cat(sprintf("  - N samples: %d\n", nrow(result)))

# Count non-missing values for each phenotype
n_valid_pheno1 <- sum(result[, 3] != -9 & !is.na(result[, 3]))
n_valid_pheno2 <- sum(result[, 4] != -9 & !is.na(result[, 4]))
n_both_valid <- sum(result[, 3] != -9 & result[, 4] != -9 &
                    !is.na(result[, 3]) & !is.na(result[, 4]))

cat(sprintf("  - N valid for %s: %d\n", pheno1_name, n_valid_pheno1))
cat(sprintf("  - N valid for %s: %d\n", pheno2_name, n_valid_pheno2))
cat(sprintf("  - N valid for both: %d\n", n_both_valid))

# Write mpheno indices file
# GCTA --mpheno uses 1-based indices relative to phenotype columns (after FID/IID)
# Since we output phenotypes in columns 3 and 4, mpheno indices are 1 and 2
writeLines(c("1", "2"), mpheno_output_file)

cat(sprintf("mpheno indices written to: %s\n", mpheno_output_file))
cat("  - Use: --mpheno 1 2\n")
