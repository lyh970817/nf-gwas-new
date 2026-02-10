#!/usr/bin/env Rscript

# prepare_bivariate_phenotypes.R
# Combine two single-phenotype files into a bivariate phenotype file
# Outputs phenotype file in GCTA format (no header) and mpheno indices

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 5) {
  stop("Usage: Rscript prepare_bivariate_phenotypes.R <pheno_file1> <pheno_file2> <phenotype1_name> <phenotype2_name> <output_file> [mpheno_output_file]")
}

pheno_file1 <- args[1]
pheno_file2 <- args[2]
pheno1_name <- args[3]
pheno2_name <- args[4]
output_file <- args[5]
mpheno_output_file <- if (length(args) >= 6) args[6] else "mpheno_indices.txt"

pheno1 <- tryCatch({
  read.table(pheno_file1, header = TRUE, sep = "", stringsAsFactors = FALSE)
}, error = function(e) {
  stop(sprintf("Failed to read phenotype file '%s': %s", pheno_file1, e$message))
})

pheno2 <- tryCatch({
  read.table(pheno_file2, header = TRUE, sep = "", stringsAsFactors = FALSE)
}, error = function(e) {
  stop(sprintf("Failed to read phenotype file '%s': %s", pheno_file2, e$message))
})

if (ncol(pheno1) < 3 || ncol(pheno2) < 3) {
  stop("Each phenotype file must have at least 3 columns: FID, IID, and phenotype")
}

col_names1 <- colnames(pheno1)
col_names2 <- colnames(pheno2)

fid_col1 <- col_names1[1]
iid_col1 <- col_names1[2]

fid_col2 <- col_names2[1]
iid_col2 <- col_names2[2]

if (!(pheno1_name %in% col_names1)) {
  available_phenos <- setdiff(col_names1, c(fid_col1, iid_col1))
  stop(sprintf("Phenotype column '%s' not found in file 1. Available columns: %s",
               pheno1_name, paste(available_phenos, collapse = ", ")))
}

if (!(pheno2_name %in% col_names2)) {
  available_phenos <- setdiff(col_names2, c(fid_col2, iid_col2))
  stop(sprintf("Phenotype column '%s' not found in file 2. Available columns: %s",
               pheno2_name, paste(available_phenos, collapse = ", ")))
}

pheno1_sub <- pheno1[, c(fid_col1, iid_col1, pheno1_name), drop = FALSE]
pheno2_sub <- pheno2[, c(fid_col2, iid_col2, pheno2_name), drop = FALSE]

merged <- merge(
  pheno1_sub,
  pheno2_sub,
  by.x = c(fid_col1, iid_col1),
  by.y = c(fid_col2, iid_col2),
  all = FALSE,
  sort = FALSE
)

colnames(merged) <- c("FID", "IID", pheno1_name, pheno2_name)

merged[is.na(merged)] <- -9

write.table(merged, output_file,
            sep = "\t",
            row.names = FALSE,
            col.names = FALSE,
            quote = FALSE)

cat(sprintf("Bivariate phenotype file created: %s\n", output_file))
cat(sprintf("  - Phenotype 1: %s\n", pheno1_name))
cat(sprintf("  - Phenotype 2: %s\n", pheno2_name))
cat(sprintf("  - N samples: %d\n", nrow(merged)))

n_valid_pheno1 <- sum(merged[, 3] != -9 & !is.na(merged[, 3]))
n_valid_pheno2 <- sum(merged[, 4] != -9 & !is.na(merged[, 4]))
n_both_valid <- sum(merged[, 3] != -9 & merged[, 4] != -9 &
                    !is.na(merged[, 3]) & !is.na(merged[, 4]))

cat(sprintf("  - N valid for %s: %d\n", pheno1_name, n_valid_pheno1))
cat(sprintf("  - N valid for %s: %d\n", pheno2_name, n_valid_pheno2))
cat(sprintf("  - N valid for both: %d\n", n_both_valid))

writeLines(c("1", "2"), mpheno_output_file)

cat(sprintf("mpheno indices written to: %s\n", mpheno_output_file))
cat("  - Use: --mpheno 1 2\n")
