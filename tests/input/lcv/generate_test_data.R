#!/usr/bin/env Rscript

# Generate test data for LCV analysis with stronger signal
set.seed(42)

n_snps <- 5000  # More SNPs for more stable estimates

# Generate SNP info
snps <- data.frame(
    SNP = paste0("rs", 1:n_snps),
    CHR = rep(1, n_snps),
    BP = seq(100000, by = 1000, length.out = n_snps)
)

# Generate LD scores (uniform for simplicity, around 1)
ldscores <- data.frame(
    SNP = snps$SNP,
    L2 = runif(n_snps, 1, 3)
)

# Simulate effect sizes with correlation
# Using a simple model where both traits share a latent factor
# and each has trait-specific variance

# Latent shared factor
shared <- rnorm(n_snps, 0, 0.15)

# Trait-specific effects
spec1 <- rnorm(n_snps, 0, 0.08)
spec2 <- rnorm(n_snps, 0, 0.08)

# Combine: trait 1 is more influenced by shared factor (partial causality)
beta1 <- shared + spec1
beta2 <- 0.5 * shared + spec2  # Trait 2 gets less of shared factor

# Sample sizes
N1 <- 50000
N2 <- 50000

# Generate Z-scores with appropriate noise
z1 <- beta1 * sqrt(N1) + rnorm(n_snps)
z2 <- beta2 * sqrt(N2) + rnorm(n_snps)

# Create summary stats files
sumstats1 <- data.frame(
    SNP = snps$SNP,
    CHR = snps$CHR,
    BP = snps$BP,
    Z = round(z1, 4)
)

sumstats2 <- data.frame(
    SNP = snps$SNP,
    CHR = snps$CHR,
    BP = snps$BP,
    Z = round(z2, 4)
)

# Write files
write.table(sumstats1, "trait1_sumstats.txt", row.names = FALSE, quote = FALSE, sep = "\t")
write.table(sumstats2, "trait2_sumstats.txt", row.names = FALSE, quote = FALSE, sep = "\t")
write.table(ldscores, "ldscores.txt", row.names = FALSE, quote = FALSE, sep = "\t")

# Print some diagnostics
cat("Generated test data files:\n")
cat(sprintf("- %d SNPs\n", n_snps))
cat(sprintf("- Trait 1 Z-score range: [%.2f, %.2f]\n", min(z1), max(z1)))
cat(sprintf("- Trait 2 Z-score range: [%.2f, %.2f]\n", min(z2), max(z2)))
cat(sprintf("- Correlation of Z-scores: %.3f\n", cor(z1, z2)))
