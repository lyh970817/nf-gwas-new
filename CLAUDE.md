# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

nf-gwas is a Nextflow pipeline for biobank-scale genome-wide association studies (GWAS) analysis. It's built using Nextflow DSL2 with containerized execution and supports multiple statistical methods (REGENIE, GCTA, BOLT-LMM, LDAK) for genetic association testing.

## Development Commands

**Setup and Testing:**
```bash
# Install nf-test framework (required for testing)
curl -fsSL https://code.askimed.com/install/nf-test | bash

# Run all tests
./nf-test test

# Run CI-style sharded tests (as used in GitHub Actions)
nf-test test --ci --shard 1/5

# Build development container
docker build -t genepi/nf-gwas .

# Run test pipeline in development mode (primary testing command)
nextflow run main.nf -profile test,development
```

**Pipeline Execution:**
```bash
# Run test pipeline with Docker
nextflow run genepi/nf-gwas -r v1.0.9 -profile test,docker

# Run with custom configuration
nextflow run genepi/nf-gwas -c <config.conf> -r v1.0.9 -profile docker

# Available profiles: test, docker, singularity, slurm, slurm_with_scratch, development
```

## Architecture

**Core Structure:**
- `main.nf` - Entry point that invokes the main NF_GWAS workflow
- `workflows/nf_gwas.nf` - Main orchestrator workflow with conditional execution paths
- `workflows/{regenie,gcta,bolt_lmm,ldak}/` - Method-specific sub-workflows
- `modules/local/` - Nextflow modules for individual tools and processes
- `conf/` - Configuration files for different execution environments

**Key Workflows:**
- `SINGLE_VARIANT_TESTS` - Handles REGENIE step1/step2 pipeline
- `GCTA_GRM`, `GCTA_GREML`, `GCTA_FASTGWA` - GCTA-based analyses
- `BOLT_LMM_REML` - BOLT-LMM mixed model analysis
- `LDAK` - LDAK kinship and REML analysis

**Configuration System:**
- Parameters defined in `nextflow.config` with extensive validation via `nextflow_schema.json`
- Profile-based execution (Docker/Singularity containers, SLURM clusters)
- Dynamic output directory handling via `params.pubDir`

## Testing Framework

Uses nf-test with unit-style testing:
- Test configuration: `nf-test.config`
- Test files: `tests/*.nf.test`
- Test profile loads `conf/test.config` with small datasets
- Tests use development profile with `genepi/nf-gwas:latest` container

## Key Development Patterns

**Parameter Handling:**
- Extensive parameter validation and deprecation warnings
- Dynamic parameter resolution (e.g., `genotypes_association` vs deprecated `genotypes_imputed`)
- Required vs optional parameter distinction in config

**Module Structure:**
- DSL2 modules with standardized input/output patterns
- Containerized processes with resource allocation from `conf/base.config`
- Channel-based data flow between workflows

**Error Handling:**
- SLURM profiles include retry logic for exit status 143
- Container-based isolation for reproducibility
- Scratch directory support for high-throughput environments

## Data Flow

1. **Input Processing**: VCF/BGEN → PLINK format conversion
2. **Quality Control**: Filtering by MAF, HWE, missingness
3. **Method Selection**: Conditional execution based on available tools/parameters
4. **Association Testing**: Parallel execution across chromosomes/chunks
5. **Post-processing**: Results aggregation, annotation, visualization

## Important Files

- `nextflow.config` - All pipeline parameters and execution profiles
- `nextflow_schema.json` - Parameter validation schema
- `environment.yml` - Conda environment with bioinformatics tools
- `Dockerfile` - Container build specification
- `conf/base.config` - Process resource allocation