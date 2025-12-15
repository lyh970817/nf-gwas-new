#!/usr/bin/env Rscript

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
    stop("Usage: calc_genotype_error.R <he_overall_file> <he_within_file> <he_across_file>")
}

# Arguments: overall HE file, within-batch HE file, across-batch HE file
he_overall_file <- args[1]
he_within_file <- args[2]
he_across_file <- args[3]

# Function to parse HE output file
parse_he_file <- function(file_path) {
    if (!file.exists(file_path)) {
        warning(paste("File does not exist:", file_path))
        return(NULL)
    }

    lines <- readLines(file_path)

    # Find the Her_All line
    her_all_line <- grep("^Her_All", lines, value = TRUE)

    if (length(her_all_line) == 0) {
        warning(paste("Her_All line not found in file:", file_path))
        return(NULL)
    }

    # Parse the Her_All line
    # Format: Her_All heritability SE size mega_intensity SE
    parts <- strsplit(her_all_line, "\\s+")[[1]]

    if (length(parts) < 3) {
        warning(paste("Invalid Her_All line format in file:", file_path))
        return(NULL)
    }

    heritability <- as.numeric(parts[2])
    se <- as.numeric(parts[3])

    return(data.frame(
        file = basename(file_path),
        heritability = heritability,
        se = se
    ))
}

# Parse all HE files
overall_result <- parse_he_file(he_overall_file)
within_result <- parse_he_file(he_within_file)
across_result <- parse_he_file(he_across_file)

# Initialize result variables
h2_overall <- NA
h2_overall_se <- NA
h2_same <- NA
h2_same_se <- NA
h2_diff <- NA
h2_diff_se <- NA
T2_statistic <- NA
statistical_test_results <- list(
    pvalue = NA,
    mean_T2samp = NA,
    sd_T2samp = NA
)

# Extract heritability estimates
if (!is.null(overall_result)) {
    h2_overall <- overall_result$heritability
    h2_overall_se <- overall_result$se
}

if (!is.null(within_result)) {
    h2_same <- within_result$heritability
    h2_same_se <- within_result$se
}

if (!is.null(across_result)) {
    h2_diff <- across_result$heritability
    h2_diff_se <- across_result$se
}

# Calculate T2 statistic: h²Same - h²Diff
# Positive values indicate genotyping errors (same-batch samples more similar)
if (!is.na(h2_same) && !is.na(h2_diff)) {
    T2_statistic <- h2_same - h2_diff
}

# Statistical test using sampling approach
# Test whether T2 is significantly greater than 0
if (!is.na(h2_same) && !is.na(h2_same_se) &&
    !is.na(h2_diff) && !is.na(h2_diff_se)) {

    # Simulation parameters
    N <- 100000

    # Generate random samples for within-batch (same) heritability
    rSame <- rnorm(N, h2_same, h2_same_se)

    # Generate random samples for across-batch (diff) heritability
    rDiff <- rnorm(N, h2_diff, h2_diff_se)

    # Calculate T2 samples: h²Same - h²Diff
    T2samp <- rSame - rDiff

    # Calculate p-value (probability that T2 <= 0)
    # If p-value is small, T2 > 0 is significant (genotyping errors detected)
    pvalue <- mean(T2samp <= 0)

    # Update statistical test results
    statistical_test_results$pvalue <- pvalue
    statistical_test_results$mean_T2samp <- mean(T2samp)
    statistical_test_results$sd_T2samp <- sd(T2samp)
}

# Create output
output_lines <- c(
    "LDAK Genotype Error Analysis Results (T2 Statistic)",
    "=====================================================",
    "",
    "Input Files:",
    paste("  Overall HE file:", he_overall_file),
    paste("  Within-batch HE file:", he_within_file),
    paste("  Across-batch HE file:", he_across_file),
    "",
    "Overall Results:",
    paste("  Heritability:", round(h2_overall, 6)),
    paste("  SE:", round(h2_overall_se, 6)),
    "",
    "Same-Batch Results (h²Same):",
    paste("  Heritability:", round(h2_same, 6)),
    paste("  SE:", round(h2_same_se, 6)),
    "",
    "Different-Batch Results (h²Diff):",
    paste("  Heritability:", round(h2_diff, 6)),
    paste("  SE:", round(h2_diff_se, 6)),
    "",
    "Genotype Error Analysis:",
    paste("  T2 Statistic (h²Same - h²Diff):", round(T2_statistic, 6)),
    "",
    "Interpretation:",
    "  T2 > 0: Same-batch samples are more similar than expected",
    "           (indicates potential genotyping errors or batch effects)",
    "  T2 ≈ 0: No evidence of batch-related errors",
    "  T2 < 0: Unexpected pattern (may indicate over-correction)",
    "",
    "Statistical Test Results:",
    paste("  P-value (H0: T2 <= 0):", round(statistical_test_results$pvalue, 6)),
    paste("  Mean T2 (from sampling):", round(statistical_test_results$mean_T2samp, 6)),
    paste("  SD T2 (from sampling):", round(statistical_test_results$sd_T2samp, 6)),
    "",
    "Significance:",
    ifelse(!is.na(statistical_test_results$pvalue),
           ifelse(statistical_test_results$pvalue < 0.05,
                  "  SIGNIFICANT: Genotype errors detected (p < 0.05)",
                  "  NOT SIGNIFICANT: No strong evidence of genotype errors (p >= 0.05)"),
           "  Cannot determine (missing data)")
)

# Write output to file
writeLines(output_lines, "genotype_error_results.txt")

cat("Genotype error analysis completed. Results written to genotype_error_results.txt\n")
