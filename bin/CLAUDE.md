# Utility Scripts (bin/)

[Root Directory](../CLAUDE.md) > **bin**

## Change Log (Changelog)

### 2025-12-12 14:21:30
- Initial documentation creation
- Documented R and Java utility scripts

---

## Module Responsibilities

The `bin/` directory contains standalone utility scripts executed by Nextflow processes. These scripts handle:

1. **Log Parsing**: Extract structured data from REGENIE logs
2. **Input Validation**: Verify phenotype/covariate file formats
3. **Statistical Computation**: Calculate inflation metrics, segment SNPs
4. **Data Extraction**: Column-based data filtering

All scripts in `bin/` are automatically added to the PATH when processes execute, enabling direct invocation without full paths.

---

## Script Index

### Java Utilities

| Script | Purpose | Inputs | Outputs | Dependencies |
|--------|---------|--------|---------|--------------|
| `RegenieLogParser.java` | Parse REGENIE logs to extract validation info | Log file path | Structured validation results | jbang, Java 11+ |
| `RegenieValidateInput.java` | Validate phenotype/covariate file format | Pheno/cov files, column lists | Validated files, error reports | jbang, Java 11+ |

### R Utilities

| Script | Purpose | Inputs | Outputs | Dependencies |
|--------|---------|--------|---------|--------------|
| `calc_inflation.R` | Calculate genomic inflation factor | REML results (full, quarter) | Inflation statistics | R, tidyverse |
| `segment_snp.R` | Segment SNPs by LD/position | SNP list, parameters | SNP group files | R, data.table |
| `extract_columns.R` | Extract specific columns from data files | Data file, column names | Subset file | R, base |

---

## Entry and Startup

### Invocation Pattern
Scripts are called directly from process `script:` blocks:

```groovy
process EXAMPLE {
    script:
    """
    RegenieLogParser.java input.log > output.txt
    """
}
```

OR via explicit interpreters:

```groovy
process EXAMPLE_R {
    script:
    """
    Rscript calc_inflation.R full_reml.txt quarter_reml.txt output.txt
    """
}
```

---

## External Interfaces

### RegenieLogParser.java

**Command-line Interface**:
```bash
java RegenieLogParser.java <regenie_log_file>
```

**Input**: REGENIE log file containing validation messages
**Output**: Structured validation report (stdout)

**Use Case**: Extract phenotype/covariate validation results from Step 1/2 logs

---

### RegenieValidateInput.java

**Command-line Interface**:
```bash
java RegenieValidateInput.java <phenotype_file> <covariate_file> \\
    --pheno-cols <col1,col2> --cov-cols <col1,col2>
```

**Inputs**:
- Phenotype file (tab/space-delimited)
- Covariate file (optional)
- Column specifications

**Outputs**:
- Validated phenotype file
- Validated covariate file
- Error log

**Use Case**: Pre-validate inputs before running REGENIE

---

### calc_inflation.R

**Command-line Interface**:
```bash
Rscript calc_inflation.R <full_reml_file> <quarter_reml_file> <output_file>
```

**Inputs**:
- Full dataset REML results (LDAK format)
- Quarter dataset REML results (LDAK format)

**Output**: Tab-delimited file with inflation statistics

**Calculation**:
```
Inflation = Variance(full) / Variance(quarter)
```

**Use Case**: Assess population structure/relatedness impact on heritability estimates

---

### segment_snp.R

**Command-line Interface**:
```bash
Rscript segment_snp.R <snp_list> <num_segments> <output_prefix>
```

**Inputs**:
- SNP list file (one SNP ID per line)
- Number of segments (integer)
- Output file prefix

**Output**: Multiple files `<prefix>_segment_1.txt`, `<prefix>_segment_2.txt`, etc.

**Use Case**: Partition SNPs for parallelized LD score calculation or GRM computation

---

### extract_columns.R

**Command-line Interface**:
```bash
Rscript extract_columns.R <input_file> <column_list> <output_file>
```

**Inputs**:
- Input data file (tab/space-delimited)
- Comma-separated column names or indices
- Output file path

**Output**: File containing only specified columns

**Use Case**: Extract specific phenotypes or covariates from large files

---

## Key Dependencies and Configuration

### Java Scripts
- **Runtime**: jbang (for portable execution)
- **Java Version**: 11+
- **Container**: Pre-compiled JARs in Docker/Singularity (`/opt/RegenieLogParser.jar`, etc.)

### R Scripts
- **R Version**: Included in conda environment
- **Packages**:
  - `data.table` (fast file I/O)
  - `tidyverse` (data manipulation)
  - Base R utilities

### Container Integration
Java utilities are compiled during Docker/Singularity build:
```dockerfile
COPY ./bin/RegenieLogParser.java ./
RUN jbang export portable -O=RegenieLogParser.jar RegenieLogParser.java
```

---

## Data Models

### REGENIE Log Format (Input to RegenieLogParser.java)
```
...
Phenotype: Y1
  - N samples: 1000
  - N covariates: 5
  - Validation: PASS
...
```

### LDAK REML Output Format (Input to calc_inflation.R)
```
Component  Variance  SE
Her_K1     0.456     0.032
Her_ALL    0.678     0.045
```

### SNP List Format (Input to segment_snp.R)
```
rs12345
rs67890
rs11111
...
```

---

## Testing and Quality

### Testing Strategy
- **Java utilities**: Tested indirectly via module tests (e.g., `regenie_step1.nf.test`)
- **R scripts**: Tested via workflow tests that invoke them

### Manual Testing
```bash
# Test Java parser
echo "Phenotype validation test" | java bin/RegenieLogParser.java /dev/stdin

# Test R inflation calculation
Rscript bin/calc_inflation.R \\
    tests/input/ldak/full_reml.txt \\
    tests/input/ldak/quarter_reml.txt \\
    test_output.txt
```

---

## Frequently Asked Questions (FAQ)

**Q: Why use jbang for Java scripts instead of regular Java?**
A: Jbang enables single-file Java scripts without separate compilation, simplifying deployment and version management in containers.

**Q: Can I modify R scripts to use different packages?**
A: Yes, but ensure new packages are added to `environment.yml` and containers are rebuilt.

**Q: How do I debug script failures?**
A: Check Nextflow work directory (e.g., `work/ab/cd1234.../`) for `.command.err` and `.command.log` files.

**Q: Are these scripts parallelized?**
A: No, scripts run serially within their process. Parallelization occurs at the Nextflow process level (multiple instances across chromosomes/phenotypes).

**Q: Can I replace R scripts with Python?**
A: Yes, add Python to `environment.yml`, write equivalent scripts, and update process invocations. Ensure containers are rebuilt.

---

## Related File List

### Java Scripts
- `RegenieLogParser.java` - Parse REGENIE validation logs
- `RegenieValidateInput.java` - Validate input file formats

### R Scripts
- `calc_inflation.R` - Genomic inflation calculation
- `segment_snp.R` - SNP partitioning for parallelization
- `extract_columns.R` - Column-based data extraction

---

## Related Documentation

- [Modules Documentation](../modules/local/CLAUDE.md)
- [REGENIE Workflows](../workflows/regenie/CLAUDE.md)
- [LDAK Workflows](../workflows/ldak/CLAUDE.md)
- [Root Documentation](../CLAUDE.md)
