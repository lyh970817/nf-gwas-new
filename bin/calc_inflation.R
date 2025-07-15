#!/usr/bin/env Rscript

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
    stop("Usage: calc_inflation.R <ldak_reml_file> <quarter_reml_file1> [quarter_reml_file2] ...")
}

# First argument is LDAK REML file, rest are quarter REML files
ldak_reml_file <- args[1]
quarter_files <- args[2:length(args)]

# Initialize all result lists
quarter_results <- list()
ldak_results <- list()

# Function to parse REML output file
parse_reml_file <- function(file_path) {
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

# Parse quarter REML files
for (file in quarter_files) {
    result <- parse_reml_file(file)
    if (!is.null(result)) {
        result$type <- "quarter"
        quarter_results[[length(quarter_results) + 1]] <- result
    }
}

# Parse LDAK REML file (single file)
ldak_result <- parse_reml_file(ldak_reml_file)
if (!is.null(ldak_result)) {
    ldak_result$type <- "ldak"
    ldak_results[[1]] <- ldak_result
}

# Initialize all variables with NA/empty values
quarter_mean_h2 <- NA
quarter_mean_se <- NA
ldak_h2 <- NA
ldak_se <- NA
inflation_factor <- NA
statistical_test_results <- list(
    n_quarters = 0,
    pvalue = NA,
    mean_T1samp = NA,
    sd_T1samp = NA
)

# Combine all results
all_results <- do.call(rbind, c(quarter_results, ldak_results))

if (nrow(all_results) == 0) {
    stop("No valid REML results found")
}

# Calculate inflation metrics
quarter_data <- all_results[all_results$type == "quarter", ]
ldak_data <- all_results[all_results$type == "ldak", ]

# Calculate mean heritability and SE for quarters
if (nrow(quarter_data) > 0) {
    quarter_mean_h2 <- mean(quarter_data$heritability, na.rm = TRUE)
    quarter_mean_se <- mean(quarter_data$se, na.rm = TRUE)
}

# Get LDAK heritability and SE
if (nrow(ldak_data) > 0) {
    ldak_h2 <- ldak_data$heritability[1]  # Assuming single LDAK result
    ldak_se <- ldak_data$se[1]
}

# Calculate inflation factor (ratio of quarter mean to LDAK)
if (!is.na(quarter_mean_h2) && !is.na(ldak_h2) && ldak_h2 != 0) {
    inflation_factor <- quarter_mean_h2 / ldak_h2
}

# Statistical test for inflation using sampling approach
# eSNP, sSNP from LDAK results; others from quarter results
if (!is.na(ldak_h2) && !is.na(ldak_se) && nrow(quarter_data) > 0) {
    eSNP <- ldak_h2
    sSNP <- ldak_se

    # Extract heritability estimates and SEs from quarters
    quarter_h2_values <- quarter_data$heritability
    quarter_se_values <- quarter_data$se

    # Remove any NA values
    valid_quarters <- !is.na(quarter_h2_values) & !is.na(quarter_se_values)
    quarter_h2_values <- quarter_h2_values[valid_quarters]
    quarter_se_values <- quarter_se_values[valid_quarters]

    if (length(quarter_h2_values) > 0) {
        # Simulation parameters
        N <- 100000

        # Generate random samples for LDAK (SNP)
        rSNP <- rnorm(N, eSNP, sSNP)

        # Generate random samples for each quarter
        quarter_samples <- list()
        for (i in 1:length(quarter_h2_values)) {
            quarter_samples[[i]] <- rnorm(N, quarter_h2_values[i], quarter_se_values[i])
        }

        # Calculate T1samp: (sum of quarters - rSNP) / (number of quarters - 1)
        quarter_sum <- Reduce("+", quarter_samples)
        T1samp <- (quarter_sum - rSNP) / (length(quarter_h2_values) - 1)

        # Calculate p-value
        pvalue <- mean(T1samp < 0)

        # Update results (variables already initialized)
        statistical_test_results$n_quarters <- length(quarter_h2_values)
        statistical_test_results$pvalue <- pvalue
        statistical_test_results$mean_T1samp <- mean(T1samp)
        statistical_test_results$sd_T1samp <- sd(T1samp)
    }
}

# Create output
output_lines <- c(
    "LDAK Inflation Analysis Results",
    "================================",
    "",
    paste("Number of quarter files processed:", length(quarter_files)),
    paste("LDAK file processed:", ldak_reml_file),
    "",
    "Quarter Results:",
    paste("  Mean Heritability:", round(quarter_mean_h2, 6)),
    paste("  Mean SE:", round(quarter_mean_se, 6)),
    "",
    "LDAK Results:",
    paste("  Heritability:", round(ldak_h2, 6)),
    paste("  SE:", round(ldak_se, 6)),
    "",
    "Inflation Analysis:",
    paste("  Inflation Factor (Quarter/LDAK):", round(inflation_factor, 6)),
    "",
    "Statistical Test Results:",
    paste("  Number of quarters used:", statistical_test_results$n_quarters),
    paste("  P-value:", round(statistical_test_results$pvalue, 6)),
    paste("  Mean T1samp:", round(statistical_test_results$mean_T1samp, 6)),
    paste("  SD T1samp:", round(statistical_test_results$sd_T1samp, 6)),
    "",
    "Individual Results:"
)

# Add individual results
for (i in 1:nrow(all_results)) {
    row <- all_results[i, ]
    output_lines <- c(output_lines, 
        paste("  ", row$file, "(", row$type, "):", 
              "H2 =", round(row$heritability, 6), 
              "SE =", round(row$se, 6)))
}

# Write output to file
writeLines(output_lines, "inflation_results.txt")

cat("Inflation analysis completed. Results written to inflation_results.txt\n")
