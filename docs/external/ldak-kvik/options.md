# LDAK-KVIK Options

Default parameters in LDAK-KVIK can be modified by adding options to the command line.

## Step 1 Options

| Argument | Description |
|----------|-------------|
| `--kvik-step1` | Specifies the name of Step 1 output files |
| `--bfile` | Identifies the .bed file for analysis |
| `--bgen` | Identifies the .bgen file for analysis |
| `--sample` | Names the .sample file associated with .bgen |
| `--pheno` | Provides the phenotype file |
| `--covar` | Provides quantitative covariate file |
| `--covar-numbers` | Selects specific covariates by index (e.g., `1,2,4-6,8`) |
| `--covar-names` | Selects specific covariates by name (e.g., `PC1,PC3,age`) |
| `--factors` | Provides categorical covariate file |
| `--max-threads` | Sets thread count for parallel processing |
| `--binary YES` | Indicates binary phenotype analysis |
| `--mpheno` | Specifies phenotype number; `--mpheno ALL` analyzes all |
| `--num-pedigree-predictors` | SNPs for structure testing (default: 512) |
| `--check-pedigree NO` | Disables structure checking |
| `--num-MCMC` | Random vectors for heritability estimation |
| `--num-divide` | Partitions for heritability calculation (default: 40) |
| `--num-scans` | Scans by Variational Bayes algorithm |
| `--cv-proportion` | Individuals used for hyperparameter determination |
| `--tolerance` | Convergence threshold multiplier (default: 10^-6) |
| `--num-calibration-predictors` | SNPs for Grammar-Gamma scaling (default: 20) |
| `--extract` | Restrict to SNPs listed in file |
| `--exclude` | Exclude SNPs listed in file |
| `--keep` | Restrict to samples listed in file |
| `--remove` | Exclude samples listed in file |

## Step 2 Options

**Critical note:** Several arguments must match those used in Step 1 (same output filename, data, phenotype files, and covariates).

| Argument | Description |
|----------|-------------|
| `--kvik-step2` | Specifies Step 2 output filename (must match Step 1) |
| `--bfile` | Identifies the .bed file for analysis |
| `--bgen` | Identifies the .bgen file for analysis |
| `--sample` | Names the .sample file associated with .bgen |
| `--pheno` | Provides the phenotype file |
| `--covar` | Provides quantitative covariate file |
| `--covar-numbers` | Selects specific covariates by index |
| `--covar-names` | Selects specific covariates by name |
| `--factors` | Provides categorical covariate file |
| `--max-threads` | Sets thread count for parallel processing |
| `--mpheno` | Specifies phenotype number; `--mpheno ALL` analyzes all |
| `--spa-test NO` | Disables saddlepoint approximation for binary phenotypes |
| `--spa-test YES` | Enables SPA for quantitative traits |
| `--extract` | Restrict to SNPs listed in file |
| `--exclude` | Exclude SNPs listed in file |
| `--keep` | Restrict to samples listed in file |
| `--remove` | Exclude samples listed in file |
| `--chr` | Analyze specific chromosome only |

## Step 3 Options

| Argument | Description |
|----------|-------------|
| `--kvik-step3` | Specifies Step 3 output filename (must match Steps 1-2) |
| `--bfile` | Identifies the .bed file for analysis |
| `--bgen` | Identifies the .bgen file for analysis |
| `--sample` | Names the .sample file associated with .bgen |
| `--genefile` | Provides gene annotation file |
| `--max-threads` | Sets thread count for parallel processing |
| `--buffer` | Window around genes in basepairs (default: 0) |
