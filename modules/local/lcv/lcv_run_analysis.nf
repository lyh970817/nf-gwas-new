/*
========================================================================================
    LCV Run Analysis Process
========================================================================================
    Runs LCV (Latent Causal Variable) analysis to infer genetically causal relationships
    between two traits using GWAS summary statistics and LD scores.

    LCV estimates the genetic causal proportion (GCP), which indicates the extent to which
    genetic correlation between traits is due to a causal effect of one trait on another.

    Reference: O'Connor & Price (2018) Nature Genetics. https://doi.org/10.1038/s41588-018-0091-z
========================================================================================
*/

process LCV_RUN_ANALYSIS {
    tag "lcv_${analysis_id}"
    publishDir "${params.pubDir}/lcv", mode: 'copy'
    label 'process_medium'

    input:
    val(analysis_id)               // Unique analysis identifier
    path(sumstats_file1)           // Summary statistics file for trait 1 (must have SNP, Z columns)
    path(sumstats_file2)           // Summary statistics file for trait 2 (must have SNP, Z columns)
    path(ldscores_file)            // LD scores file (must have SNP, L2 columns)
    val(trait1_name)               // Name of trait 1
    val(trait2_name)               // Name of trait 2
    val(no_blocks)                 // Number of jackknife blocks (default: 100)
    val(sig_threshold)             // Chi-square threshold for excluding large-effect SNPs (default: 30)
    val(crosstrait_intercept)      // Estimate cross-trait LDSC intercept (0 or 1)
    val(ldsc_intercept)            // Estimate LDSC intercept (0 or 1)

    output:
    path "${analysis_id}.lcv.results.txt", emit: results
    path "${analysis_id}.lcv.log",         emit: log_file

    script:
    """
    #!/usr/bin/env Rscript

    # ============================================================================
    # LCV Analysis Script
    # ============================================================================

    # Logging function
    log_file <- file("${analysis_id}.lcv.log", open = "wt")
    log_msg <- function(msg) {
        timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
        cat(paste0("[", timestamp, "] ", msg, "\\n"), file = log_file)
        cat(paste0("[", timestamp, "] ", msg, "\\n"))
    }

    log_msg("Starting LCV analysis")
    log_msg(paste("Analysis ID:", "${analysis_id}"))
    log_msg(paste("Trait 1:", "${trait1_name}"))
    log_msg(paste("Trait 2:", "${trait2_name}"))

    # ============================================================================
    # LCV Functions (from https://github.com/lukejoconnor/LCV)
    # ============================================================================

    # Weighted regression of y on X with weights w
    WeightedRegression <- function(X, y, w = array(1, length(y), 1)) {
        beta <- solve(t(X * w) %*% X, t(X * w) %*% y)
        return(beta)
    }

    # Weighted mean of y with weights w
    WeightedMean <- function(y, w = array(1, c(length(y), 1))) {
        mu <- sum(y %*% w) / sum(w)
        return(mu)
    }

    # Estimator of mixed 4th moments
    EstimateK4 <- function(ell, z.1, z.2, crosstrait.intercept = 1, ldsc.intercept = 1,
                           weights = 1/pmax(1, ell), sig.threshold = .Machine\$integer.max,
                           n.1 = 1, n.2 = 1, intercept.12 = 0, nargout = 3) {

        # LDSC regression on each trait
        if (ldsc.intercept == 0) {
            intercept.1 <- 1/n.1
            intercept.2 <- 1/n.2
            temp <- WeightedRegression(ell, z.1^2 - intercept.1, weights)
            h2g.1 <- temp[1]
            temp <- WeightedRegression(ell, z.2^2 - intercept.2, weights)
            h2g.2 <- temp[1]
        } else {
            # Exclude significant SNPs when calculating LDSC intercept
            keep.snps.1 <- z.1^2 <= sig.threshold * mean(z.1^2)
            temp <- WeightedRegression(cbind(ell[keep.snps.1], matrix(1, sum(keep.snps.1))),
                                       z.1[keep.snps.1]^2, weights[keep.snps.1])
            intercept.1 <- temp[2]

            # Include significant SNPs when computing heritability
            temp <- WeightedRegression(ell, z.1^2 - intercept.1, weights)
            h2g.1 <- temp[1]

            keep.snps.2 <- z.2^2 <= sig.threshold * mean(z.2^2)
            temp <- WeightedRegression(cbind(ell[keep.snps.2], matrix(1, sum(keep.snps.2))),
                                       z.2[keep.snps.2]^2, weights[keep.snps.2])
            intercept.2 <- temp[2]

            temp <- WeightedRegression(ell, z.2^2 - intercept.2, weights)
            h2g.2 <- temp[1]
        }

        # Ensure h2g estimates are positive (clamp to small positive value)
        h2g.1 <- max(h2g.1, 1e-10)
        h2g.2 <- max(h2g.2, 1e-10)

        # Cross-trait LDSC regression
        if (crosstrait.intercept == 0) {
            temp <- WeightedRegression(ell, z.1 * z.2 - intercept.12, weights)
            rho <- temp / sqrt(h2g.1 * h2g.2)
        } else {
            keep.snps.12 <- (z.1^2 < sig.threshold * mean(z.1^2)) * (z.2^2 < sig.threshold * mean(z.2^2)) == 1
            temp <- WeightedRegression(cbind(ell[keep.snps.12], matrix(1, sum(keep.snps.12))),
                                       z.1[keep.snps.12] * z.2[keep.snps.12], weights[keep.snps.12])
            intercept.12 <- temp[2]
            temp <- WeightedRegression(ell, z.1 * z.2 - intercept.12, weights)
            rho <- temp[1] / sqrt(h2g.1 * h2g.2)
        }

        # Clamp rho to valid range
        rho <- max(min(rho, 1), -1)

        # Normalize effect sizes (ensure positive values under sqrt)
        s.1 <- sqrt(max(WeightedMean(z.1^2, weights) - intercept.1, 1e-10))
        s.2 <- sqrt(max(WeightedMean(z.2^2, weights) - intercept.2, 1e-10))
        nz.1 <- z.1 / s.1
        nz.2 <- z.2 / s.2

        # Estimates of mixed 4th moments
        k41 <- WeightedMean(nz.2 * nz.1^3 - 3 * nz.1 * nz.2 * (intercept.1/s.1^2) -
                           3 * (nz.1^2 - intercept.1/s.1^2) * intercept.12/s.1/s.2, weights)
        k42 <- WeightedMean(nz.1 * nz.2^3 - 3 * nz.1 * nz.2 * (intercept.2/s.2^2) -
                           3 * (nz.2^2 - intercept.2/s.2^2) * intercept.12/s.1/s.2, weights)

        argout <- c(rho, k41, k42, intercept.12, s.1, s.2, intercept.1, intercept.2)
        return(argout[1:nargout])
    }

    # Main LCV function
    RunLCV <- function(ell, z.1, z.2, no.blocks = 100, crosstrait.intercept = 1,
                       ldsc.intercept = 1, weights = 1/pmax(1, ell),
                       sig.threshold = .Machine\$integer.max, n.1 = 1, n.2 = 1,
                       intercept.12 = 0) {

        M <- length(z.1)

        # Jackknife standard errors
        jk.estimates <- matrix(0, no.blocks, 8)
        block.size <- floor(M / no.blocks)

        for (jj in 1:no.blocks) {
            ind <- setdiff(1:M, (1 + (jj - 1) * block.size):(jj * block.size))
            jk.estimates[jj, ] <- EstimateK4(ell[ind], z.1[ind], z.2[ind],
                                             crosstrait.intercept, ldsc.intercept,
                                             weights[ind], sig.threshold, n.1, n.2,
                                             intercept.12, 8)
        }

        # Full-data estimates
        full.estimates <- EstimateK4(ell, z.1, z.2, crosstrait.intercept, ldsc.intercept,
                                     weights, sig.threshold, n.1, n.2, intercept.12, 8)

        # Jackknife means and covariance
        jk.mean <- colMeans(jk.estimates)
        jk.cov <- (no.blocks - 1) / no.blocks * t(jk.estimates - matrix(rep(jk.mean, no.blocks),
                                                   byrow = TRUE, nrow = no.blocks)) %*%
                  (jk.estimates - matrix(rep(jk.mean, no.blocks), byrow = TRUE, nrow = no.blocks))

        rho.err <- sqrt(jk.cov[1, 1])

        # Posterior mean and SE for GCP
        S.12 <- jk.cov[2:3, 2:3]
        mu <- c(full.estimates[2], full.estimates[3])
        rho <- full.estimates[1]

        if (rho > 0) {
            x.lim <- c(-1, 1)
        } else {
            x.lim <- c(-1, 1)
        }

        # Grid for GCP
        x <- seq(x.lim[1], x.lim[2], length.out = 1000)
        gcp.posterior <- rep(0, length(x))

        for (ii in 1:length(x)) {
            xx <- x[ii]
            if (abs(xx) == 1) {
                next
            }

            mu.x <- abs(rho) * c((1 + xx) / 2, (1 - xx) / 2)

            # Check for positive definiteness
            if (det(S.12) <= 0) {
                gcp.posterior[ii] <- 0
                next
            }

            gcp.posterior[ii] <- exp(-0.5 * t(mu - mu.x) %*% solve(S.12) %*% (mu - mu.x))
        }

        # Normalize posterior (handle edge case where all zeros)
        if (sum(gcp.posterior) > 0) {
            gcp.posterior <- gcp.posterior / sum(gcp.posterior)
        } else {
            gcp.posterior <- rep(1/length(gcp.posterior), length(gcp.posterior))
        }

        # Posterior mean and SE (ensure non-negative variance)
        gcp.pm <- sum(x * gcp.posterior)
        gcp.var <- max(sum(x^2 * gcp.posterior) - gcp.pm^2, 0)
        gcp.pse <- sqrt(gcp.var)

        # Z-score for GCP != 0 (handle potential division by zero)
        denom <- jk.cov[2, 2] + jk.cov[3, 3] - 2 * jk.cov[2, 3]
        if (denom > 0) {
            zscore <- sign(rho) * (full.estimates[2] - full.estimates[3]) / sqrt(denom)
        } else {
            zscore <- 0
        }

        pval.gcpzero.2tailed <- 2 * pnorm(-abs(zscore))

        # P-values for GCP = 1 or -1
        pval.fullycausal <- c(NA, NA)

        # Z-scores for heritability (handle potential division by zero)
        h2.denom.1 <- jk.cov[5, 5] * 4 * jk.mean[5]^2 + jk.cov[7, 7]
        h2.denom.2 <- jk.cov[6, 6] * 4 * jk.mean[6]^2 + jk.cov[8, 8]
        h2.zscore.1 <- if (h2.denom.1 > 0) (jk.mean[5]^2 - jk.mean[7]) / sqrt(h2.denom.1) else 0
        h2.zscore.2 <- if (h2.denom.2 > 0) (jk.mean[6]^2 - jk.mean[8]) / sqrt(h2.denom.2) else 0

        return(list(
            zscore = zscore,
            pval.gcpzero.2tailed = pval.gcpzero.2tailed,
            gcp.pm = gcp.pm,
            gcp.pse = gcp.pse,
            rho.est = rho,
            rho.err = rho.err,
            pval.fullycausal = pval.fullycausal,
            h2.zscore = c(h2.zscore.1, h2.zscore.2)
        ))
    }

    # ============================================================================
    # Load and process data
    # ============================================================================

    log_msg("Loading summary statistics and LD scores")

    # Read summary statistics
    sumstats1 <- read.table("${sumstats_file1}", header = TRUE, stringsAsFactors = FALSE)
    sumstats2 <- read.table("${sumstats_file2}", header = TRUE, stringsAsFactors = FALSE)
    ldscores <- read.table("${ldscores_file}", header = TRUE, stringsAsFactors = FALSE)

    log_msg(paste("Trait 1 SNPs:", nrow(sumstats1)))
    log_msg(paste("Trait 2 SNPs:", nrow(sumstats2)))
    log_msg(paste("LD scores SNPs:", nrow(ldscores)))

    # Merge datasets by SNP
    merged <- merge(sumstats1, sumstats2, by = "SNP", suffixes = c(".1", ".2"))
    merged <- merge(merged, ldscores, by = "SNP")
    log_msg(paste("SNPs after merging:", nrow(merged)))

    if (nrow(merged) == 0) {
        log_msg("ERROR: No overlapping SNPs found between datasets")
        stop("No overlapping SNPs")
    }

    # Sort by chromosome and position if available
    if ("CHR" %in% names(merged) && "BP" %in% names(merged)) {
        merged <- merged[order(merged\$CHR, merged\$BP), ]
        log_msg("Data sorted by chromosome and position")
    } else if ("CHR.1" %in% names(merged) && "BP.1" %in% names(merged)) {
        merged <- merged[order(merged\$CHR.1, merged\$BP.1), ]
        log_msg("Data sorted by chromosome and position")
    }

    # Extract Z-scores and LD scores
    # Check for Z column naming
    z1_col <- if ("Z.1" %in% names(merged)) "Z.1" else if ("Z" %in% names(merged)) "Z" else "ZSCORE.1"
    z2_col <- if ("Z.2" %in% names(merged)) "Z.2" else "ZSCORE.2"
    l2_col <- if ("L2" %in% names(merged)) "L2" else if ("ldscore" %in% names(merged)) "ldscore" else "LDSCORE"

    z.1 <- merged[[z1_col]]
    z.2 <- merged[[z2_col]]
    ell <- merged[[l2_col]]

    # Remove NA values
    valid <- !is.na(z.1) & !is.na(z.2) & !is.na(ell)
    z.1 <- z.1[valid]
    z.2 <- z.2[valid]
    ell <- ell[valid]

    log_msg(paste("Valid SNPs for analysis:", length(z.1)))

    # ============================================================================
    # Run LCV analysis
    # ============================================================================

    log_msg("Running LCV analysis")
    log_msg(paste("Number of jackknife blocks:", ${no_blocks}))
    log_msg(paste("Significance threshold:", ${sig_threshold}))
    log_msg(paste("Cross-trait intercept estimation:", ${crosstrait_intercept}))
    log_msg(paste("LDSC intercept estimation:", ${ldsc_intercept}))

    tryCatch({
        # Set weights (inverse LD score)
        weights <- 1 / pmax(1, ell)

        # Run LCV
        lcv_result <- RunLCV(
            ell = ell,
            z.1 = z.1,
            z.2 = z.2,
            no.blocks = ${no_blocks},
            crosstrait.intercept = ${crosstrait_intercept},
            ldsc.intercept = ${ldsc_intercept},
            weights = weights,
            sig.threshold = ${sig_threshold}
        )

        log_msg("LCV analysis completed successfully")
        log_msg(sprintf("Genetic correlation (rho): %.4f (SE: %.4f)", lcv_result\$rho.est, lcv_result\$rho.err))
        log_msg(sprintf("Genetic causal proportion (GCP): %.4f (SE: %.4f)", lcv_result\$gcp.pm, lcv_result\$gcp.pse))
        log_msg(sprintf("Z-score for GCP != 0: %.4f", lcv_result\$zscore))
        log_msg(sprintf("P-value (two-tailed): %.4e", lcv_result\$pval.gcpzero.2tailed))

        # ============================================================================
        # Write results
        # ============================================================================

        results <- data.frame(
            analysis_id = "${analysis_id}",
            trait1 = "${trait1_name}",
            trait2 = "${trait2_name}",
            n_snps = length(z.1),
            rho = lcv_result\$rho.est,
            rho_se = lcv_result\$rho.err,
            gcp = lcv_result\$gcp.pm,
            gcp_se = lcv_result\$gcp.pse,
            zscore = lcv_result\$zscore,
            pval = lcv_result\$pval.gcpzero.2tailed,
            h2_zscore_trait1 = lcv_result\$h2.zscore[1],
            h2_zscore_trait2 = lcv_result\$h2.zscore[2]
        )

        write.table(results, "${analysis_id}.lcv.results.txt",
                    row.names = FALSE, quote = FALSE, sep = "\\t")
        log_msg("Results written to ${analysis_id}.lcv.results.txt")

    }, error = function(e) {
        log_msg(paste("ERROR:", e\$message))
        stop(e)
    })

    log_msg("LCV analysis completed")
    close(log_file)
    """
}
