#!/usr/bin/env Rscript

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if there are enough arguments
if (length(args) < 3) {
  stop("Usage: Rscript extract_columns.R <file_path> <column1,column2,...> <output_file> <unspecified_output_file>")
}

# First argument is the file path
file_path <- args[1]

# Second argument is a comma-separated list of column names
specified_columns <- unlist(strsplit(args[2], ","))

# Third argument is the output file path for specified columns
output_file <- args[3]

# Fourth argument is the output file path for unspecified columns
unspecified_output_file <- args[4]

# Read the input file (space-delimited)
data <- read.table(file_path, header = TRUE, sep = " ")

# Check if the file has at least two columns to extract
if (ncol(data) < 2) {
  stop("The input file must have at least two columns.")
}

# Get the first two columns by their names
first_two_columns <- colnames(data)[1:2]

# Combine the first two columns with the specified columns
all_columns <- unique(c(first_two_columns, specified_columns))

# Check if all specified columns exist in the file
missing_columns <- setdiff(all_columns, colnames(data))
if (length(missing_columns) > 0) {
  stop(paste("The following specified columns do not exist in the file:", paste(missing_columns, collapse = ", ")))
}

# Extract the specified columns including the first two columns
extracted_data <- data[, all_columns, drop = FALSE]

# Identify the unspecified columns (excluding the first two columns)
unspecified_columns <- setdiff(colnames(data), all_columns)

# Combine the first two columns with the unspecified columns
unspecified_data <- data[, unique(c(first_two_columns, unspecified_columns)), drop = FALSE]

# Write the extracted specified columns to the output file
write.table(extracted_data, output_file, sep = " ", row.names = FALSE, quote = FALSE)
cat("Specified columns extracted and saved to", output_file, "\n")

# Write the first two columns with the unspecified columns to the other output file
write.table(unspecified_data, unspecified_output_file, sep = " ", row.names = FALSE, quote = FALSE)
cat("First two columns and unspecified columns saved to", unspecified_output_file, "\n")
