#!/usr/bin/env Rscript
# Create dummy LDAK tagging files for testing
# This script generates both thin (10-column) and BLD (75-column) tagging files
# Using numeric SNP IDs to match nf-gwas test data
# IMPORTANT: LDAK tagging files use SPACE delimiters, not tabs!

set.seed(42)

# Number of SNPs to include (matching test data format)
n_snps <- 100

# Generate SNP information
snp_ids <- as.character(1:n_snps)  # Numeric IDs as in test data
allele1 <- sample(c("A", "C", "G", "T"), n_snps, replace = TRUE)
allele2 <- sapply(allele1, function(a) {
  pool <- setdiff(c("A", "C", "G", "T"), a)
  sample(pool, 1)
})

# Generate realistic values based on real tagging files
neighbours <- sample(200:250, n_snps, replace = TRUE)  # LD neighbourhood size
tagging <- round(runif(n_snps, 1, 8), 3)  # Tagging values
maf <- round(runif(n_snps, 0.01, 0.5), 6)  # MAF range

# For thin format: binary weights (0 or 1 for LD-thinned predictors)
# Use 4-decimal format like real files
weight_thin <- ifelse(runif(n_snps) > 0.3, 1.0000, 0.0000)

# For BLD format: continuous weights
weight_bld <- ifelse(weight_thin == 1, 1, 0)

# Expected heritability (small values, 4 decimal places)
exp_h2_thin <- round(maf * (1-maf) * 0.001, 4)
exp_h2_bld <- round(runif(n_snps, 0.01, 0.6), 4)

# Base values
base_thin <- round(tagging * (1 + runif(n_snps, 0, 0.2)), 4)
base_bld <- round(runif(n_snps, 5, 30), 4)

# ============================================================
# Create THIN format tagging file (10 columns) - SPACE delimited
# ============================================================
thin_df <- data.frame(
  Predictor = snp_ids,
  A1 = allele1,
  A2 = allele2,
  Neighbours = neighbours,
  Tagging = sprintf("%.3f", tagging),
  Weight = sprintf("%.4f", weight_thin),
  MAF = sprintf("%.6f", maf),
  Categories = 1,
  Exp_Heritability = sprintf("%.4f", exp_h2_thin),
  Base = sprintf("%.4f", base_thin)
)

# Write with space delimiter (LDAK format)
write.table(thin_df, "test_thin.tagging",
            row.names = FALSE, quote = FALSE, sep = " ")

# Add LDAK footer lines (required by LDAK --sum-hers)
# Format from real LDAK tagging files:
# The relative contribution of the Base to each category <value>
# There are <ref> reference <reg> regression <h2> heritability predictors <total>
base_contribution <- sum(base_thin)
footer_lines <- c(
  sprintf("The relative contribution of the Base to each category %.4f", base_contribution),
  sprintf("There are %d reference %d regression %d heritability predictors %d", n_snps, n_snps, n_snps, n_snps)
)
write(footer_lines, "test_thin.tagging", append = TRUE)

cat("Created: test_thin.tagging (10 columns,", n_snps, "SNPs, space-delimited, with LDAK footer)\n")

# ============================================================
# Create BLD format tagging file (75 columns) - SPACE delimited
# ============================================================

# Generate 65 annotation columns with realistic values
n_annotations <- 65

# Create annotation matrix with formatted values
annotation_matrix <- matrix(
  sprintf("%.4f", runif(n_snps * n_annotations, 0, 25)),
  nrow = n_snps,
  ncol = n_annotations
)
colnames(annotation_matrix) <- paste0("Annotation_", 1:n_annotations)

# BLD format has more complex structure
bld_df <- data.frame(
  Predictor = snp_ids,
  A1 = allele1,
  A2 = allele2,
  Neighbours = neighbours,
  Tagging = sprintf("%.3f", tagging),
  Weight = weight_bld,
  MAF = sprintf("%.6f", maf),
  Categories = sample(15:40, n_snps, replace = TRUE),
  Exp_Heritability = sprintf("%.4f", exp_h2_bld),
  annotation_matrix,
  Base = sprintf("%.4f", base_bld)
)

# Write with space delimiter (LDAK format)
write.table(bld_df, "test_bld.tagging",
            row.names = FALSE, quote = FALSE, sep = " ")

# Add LDAK footer lines for BLD format
# BLD format has multiple categories (annotations), so footer is more complex
base_bld_contribution <- sum(base_bld)
footer_lines_bld <- c(
  sprintf("The relative contribution of the Base to each category %.4f", base_bld_contribution),
  sprintf("There are %d reference %d regression %d heritability predictors %d", n_snps, n_snps, n_snps, n_snps)
)
write(footer_lines_bld, "test_bld.tagging", append = TRUE)

cat("Created: test_bld.tagging (75 columns,", n_snps, "SNPs, space-delimited, with LDAK footer)\n")

# ============================================================
# Create dummy summary statistics file for SumHer testing
# ============================================================
# Format required: Predictor A1 A2 n Z
# Using same SNP IDs as tagging file

summary_stats <- data.frame(
  Predictor = snp_ids,
  A1 = allele1,
  A2 = allele2,
  n = 10000,  # Sample size
  Z = round(rnorm(n_snps, 0, 1.5), 4)  # Z-scores (some significant)
)

# Add a few significant SNPs for realistic results
sig_indices <- sample(1:n_snps, 5)
summary_stats$Z[sig_indices] <- round(rnorm(5, 0, 3), 4)

# Write with space delimiter
write.table(summary_stats, "test_gwas_summary.txt",
            row.names = FALSE, quote = FALSE, sep = " ")

cat("Created: test_gwas_summary.txt (5 columns,", n_snps, "SNPs, space-delimited)\n")

# ============================================================
# Create a second summary stats file for SumCors testing
# ============================================================
summary_stats2 <- data.frame(
  Predictor = snp_ids,
  A1 = allele1,
  A2 = allele2,
  n = 10000,
  Z = round(rnorm(n_snps, 0, 1.5), 4)
)

# Add correlated significant SNPs (for genetic correlation)
summary_stats2$Z[sig_indices] <- round(summary_stats$Z[sig_indices] * 0.7 + rnorm(5, 0, 1), 4)

# Write with space delimiter
write.table(summary_stats2, "test_gwas_summary2.txt",
            row.names = FALSE, quote = FALSE, sep = " ")

cat("Created: test_gwas_summary2.txt (5 columns,", n_snps, "SNPs, space-delimited)\n")

cat("\n=== File Summary ===\n")
cat("All files use SPACE delimiters (LDAK format)\n")
cat("test_thin.tagging     - 10 columns (LDAK-Thin format for SumCors)\n")
cat("test_bld.tagging      - 75 columns (BLD format for SumHer with enrichment)\n")
cat("test_gwas_summary.txt - GWAS summary statistics (trait 1)\n")
cat("test_gwas_summary2.txt - GWAS summary statistics (trait 2)\n")
