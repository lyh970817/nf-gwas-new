#!/usr/bin/env Rscript

# Get the filename and output directory from command-line arguments
args <- commandArgs(trailingOnly = TRUE)
filename <- args[1] # The first argument is the filename
out <- args[2] # The first argument is the filename

# Read the data
lds_seg <- read.table(filename, header = TRUE, colClasses = c("character", rep("numeric", 8)))

# Calculate quartiles
quartiles <- summary(lds_seg$ldscore_SNP)

# Define the groups
lb1 <- which(lds_seg$ldscore_SNP <= quartiles[2])
lb2 <- which(lds_seg$ldscore_SNP > quartiles[2] & lds_seg$ldscore_SNP <= quartiles[3])
lb3 <- which(lds_seg$ldscore_SNP > quartiles[3] & lds_seg$ldscore_SNP <= quartiles[5])
lb4 <- which(lds_seg$ldscore_SNP > quartiles[5])

# Get SNPs in each group
lb1_snp <- lds_seg$SNP[lb1]
lb2_snp <- lds_seg$SNP[lb2]
lb3_snp <- lds_seg$SNP[lb3]
lb4_snp <- lds_seg$SNP[lb4]

# Write each group to a separate file
write.table(lb1_snp, paste(out, "snp_group1.txt", sep = "_"), row.names = FALSE, quote = FALSE, col.names = FALSE, append = TRUE)
write.table(lb2_snp, paste(out, "snp_group2.txt", sep = "_"), row.names = FALSE, quote = FALSE, col.names = FALSE, append = TRUE)
write.table(lb3_snp, paste(out, "snp_group3.txt", sep = "_"), row.names = FALSE, quote = FALSE, col.names = FALSE, append = TRUE)
write.table(lb4_snp, paste(out, "snp_group4.txt", sep = "_"), row.names = FALSE, quote = FALSE, col.names = FALSE, append = TRUE)
