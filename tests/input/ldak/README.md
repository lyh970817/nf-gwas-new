# LDAK Test Input Data

[Testing Documentation](../../CLAUDE.md) > **ldak**

This directory contains test data files for LDAK module tests.

---

## Directory Structure

```
ldak/
├── README.md                     # This file
├── phenotype.noheader.txt        # Phenotype file (FID IID Y1 format)
├── covariates.quant.noheader.txt # Quantitative covariates (no header)
├── covariates.cat.noheader.txt   # Categorical covariates (no header)
├── per_chr_grm/                  # Per-chromosome kinship matrices
│   ├── README.md
│   ├── chr01.vcf.grm.*           # Chr1 GRM files
│   ├── chr02.vcf.grm.*           # Chr2 GRM files
│   └── ldak_test.mgrm            # Multi-GRM list file
├── combined_grm/                 # Combined genome-wide GRM
│   ├── README.md
│   └── ldak_grm.grm.*            # Combined GRM files
├── adjusted_grm/                 # Covariate-adjusted GRM
│   ├── README.md
│   └── ldak_grm_adj.grm.*        # Adjusted GRM files (incl. .root)
├── filtered/                     # Relatedness filtering results
│   ├── README.md
│   └── ldak_grm.*                # Keep/lose/maxrel files (matches GRM prefix)
├── he_results/                   # HE regression outputs
│   ├── README.md
│   ├── he_ldak_grm.*             # Standard HE results
│   ├── he_ldak_grm_adj.*         # Adjusted GRM HE results
│   └── he_batch_grm.*            # Batch HE for genotype error
├── pcgc_results/                 # PCGC regression outputs
│   ├── README.md
│   ├── pcgc_ldak_grm.*           # Standard PCGC results
│   └── pcgc_ldak_grm_adj.*       # Adjusted GRM PCGC results
├── reml_results/                 # REML variance estimation outputs
│   ├── README.md
│   ├── reml_ldak_grm.*           # Full-genome REML results
│   └── reml_chr*.vcf.reml        # Per-chromosome REML results
├── inflation_results/            # Genomic inflation results
│   ├── README.md
│   └── inflation_results.txt     # Inflation statistics
├── thin_predictors/              # LD-based thinning outputs
│   ├── README.md
│   ├── example.thin.in           # Thinned SNP list
│   └── weights.thin              # SNP weights
└── sumher/                       # Summary statistics test data
    ├── README.md
    ├── test_gwas_summary.txt     # GWAS summary stats (trait 1)
    ├── test_gwas_summary2.txt    # GWAS summary stats (trait 2)
    ├── test_thin.tagging*        # LDAK-Thin tagging files
    └── test_bld.tagging*         # BLD tagging files
```

---

## Data Source

Test data generated from previous LDAK workflow runs with:
- **Samples**: 500 individuals from `tests/input/example.{bed,bim,fam}`
- **Chromosomes**: 2 (chr01, chr02 from VCF conversion)
- **Variants**: ~1000 total
- **Phenotypes**: Quantitative (Y1) and binary

---

## Root-Level Files

### Phenotype and Covariate Files

| File | Description | Format |
|------|-------------|--------|
| `phenotype.noheader.txt` | Quantitative phenotype | FID IID Y1 (no header) |
| `covariates.quant.noheader.txt` | Quantitative covariates | FID IID COV1 COV2... |
| `covariates.cat.noheader.txt` | Categorical covariates | FID IID CAT1 CAT2... |

**Note**: LDAK requires no-header format for phenotype/covariate files.

---

## Test Coverage Summary

| Test File | Process | Status | Data Used |
|-----------|---------|--------|-----------|
| `add_grms.nf.test` | ADD_GRMS | ✅ PASS | `per_chr_grm/` |
| `adjust_grm.nf.test` | ADJUST_GRM_LDAK | ✅ PASS | `combined_grm/`, phenotype, covariates |
| `calc_genotype_error_t2.nf.test` | CALC_GENOTYPE_ERROR_T2 | ✅ PASS | `he_results/` (batch files) |
| `calc_inflation.nf.test` | CALC_INFLATION | ✅ PASS | `reml_results/` |
| `calc_kins_human.nf.test` | CALC_KINS_HUMAN | ✅ PASS | Base genotype files |
| `calc_kins_meta.nf.test` | CALC_KINS_META | ⏭️ SKIP | (Workflow-level test) |
| `calc_kins_uniform.nf.test` | CALC_KINS_UNIFORM | ✅ PASS | Base genotype files |
| `calc_kins_weights.nf.test` | CALC_KINS_WEIGHTS | ✅ PASS | Base + `thin_predictors/` |
| `create_thin_weights.nf.test` | CREATE_THIN_WEIGHTS | ✅ PASS | `thin_predictors/` |
| `filter_relatedness.nf.test` | FILTER_RELATEDNESS | ✅ PASS | `combined_grm/` |
| `ldak_he.nf.test` | LDAK_HE | ✅ PASS | `adjusted_grm/`, `filtered/` |
| `ldak_pcgc.nf.test` | LDAK_PCGC | ✅ PASS | `adjusted_grm/`, `filtered/` |
| `ldak_reml.nf.test` | LDAK_REML | ✅ PASS | `combined_grm/`, `filtered/` |
| `ldak_sumcors.nf.test` | LDAK_SUMCORS | ✅ PASS | `sumher/` |
| `ldak_sumher.nf.test` | LDAK_SUMHER | ✅ PASS | `sumher/` |
| `make_mgrm_ldak.nf.test` | MAKE_MGRM_LDAK | ✅ PASS | (No external files) |
| `thin_predictors.nf.test` | THIN_PREDICTORS | ✅ PASS | Base genotype files |

**Total**: 21 tests (20 passing + 1 skipped)

---

## Data Flow Diagram

```
                              Base Genotype Data
                        (tests/input/example.{bed,bim,fam})
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
             THIN_PREDICTORS   CALC_KINS_UNIFORM  CALC_KINS_HUMAN
                    │                 │                 │
                    ▼                 │                 │
           thin_predictors/           │                 │
                    │                 │                 │
                    ▼                 │                 │
          CREATE_THIN_WEIGHTS         │                 │
                    │                 │                 │
                    ▼                 │                 │
           CALC_KINS_WEIGHTS          │                 │
                    └────────────┬────┴─────────────────┘
                                 │
                                 ▼
                          per_chr_grm/
                                 │
                                 ▼
                            ADD_GRMS
                                 │
                                 ▼
                          combined_grm/
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
                    ▼            ▼            ▼
          ADJUST_GRM_LDAK  FILTER_RELATEDNESS  LDAK_REML
                    │            │            │
                    ▼            │            ▼
             adjusted_grm/       │      reml_results/
                    │            │            │
                    ├────────────┘            ▼
                    │                   CALC_INFLATION
                    │                         │
                    ▼                         ▼
              ┌─────┴─────┐           inflation_results/
              │           │
              ▼           ▼
           LDAK_HE    LDAK_PCGC
              │           │
              ▼           ▼
         he_results/  pcgc_results/
              │
              ▼
     CALC_GENOTYPE_ERROR_T2
```

---

## Usage

### Run All LDAK Tests
```bash
nf-test test tests/modules/local/ldak/ --profile test,singularity
```

### Run Specific Test
```bash
nf-test test tests/modules/local/ldak/ldak_he.nf.test --profile test,singularity
```

### Update Snapshots After Changes
```bash
nf-test test tests/modules/local/ldak/ --update-snapshot --profile test,singularity
```

---

## Subdirectory Documentation

Each subdirectory has its own README.md with:
- File descriptions and formats
- Data generation details
- Usage examples for tests
- Related documentation links

See individual subdirectory READMEs for details.

---

## Related Documentation

- [LDAK Module Documentation](../../../modules/local/ldak/CLAUDE.md)
- [LDAK Workflow Documentation](../../../workflows/ldak/CLAUDE.md)
- [Testing Documentation](../../CLAUDE.md)
- [LDAK Heritability Reference](../../../modules/local/ldak/HERITABILITY_REFERENCE.md)
- [LDAK Kinship Reference](../../../modules/local/ldak/KINSHIP_REFERENCE.md)
- [LDAK QC Reference](../../../modules/local/ldak/QC_REFERENCE.md)
