# Configuration (conf/)

[Root Directory](../CLAUDE.md) > **conf**

## Change Log (Changelog)

### 2025-12-12 14:21:30
- Initial documentation creation
- Documented base and test configuration profiles

---

## Module Responsibilities

Configuration files define:
1. **Resource Allocation**: CPU, memory, time limits per process
2. **Process Behavior**: Error handling, retry strategies
3. **Test Parameters**: Minimal datasets and parameters for CI/CD
4. **Profile-specific Settings**: Environment-dependent configurations

These files are included from `nextflow.config` and control pipeline execution behavior.

---

## Configuration Files

### base.config

**Purpose**: Default resource allocation for all processes

**Key Sections**:

#### Process-specific Resources
```groovy
withName: 'REGENIE_STEP1_RUN' {
    cpus = { 8 * task.attempt }
    memory = { 16.GB * task.attempt }
}
```

**Resource Scaling Pattern**:
- Resources multiply by `task.attempt` (1, 2, 3) on retry
- Enables automatic resource increase after failures

#### Process Labels
Used in `slurm_singularity` profile (nextflow.config):
```groovy
withLabel:process_low {
    cpus = 2
    memory = 6.GB
    time = 4.h
}

withLabel:process_medium {
    cpus = 6
    memory = 36.GB
    time = 8.h
}

withLabel:process_high {
    cpus = 12
    memory = 72.GB
    time = 16.h
}
```

#### Error Handling Strategy
```groovy
errorStrategy = 'retry'
maxRetries = 3
```

**All processes** inherit retry behavior unless overridden.

---

### test.config

**Purpose**: Test profile with minimal data and resource requirements

**Key Parameters**:
```groovy
params {
    project = 'test-gwas'
    genotypes_prediction = "$baseDir/tests/input/pipeline/example.{bim,bed,fam}"
    genotypes_association = "$baseDir/tests/input/pipeline/chr*.vcf.gz"
    genotypes_build = 'hg19'
    phenotypes_filename = "$baseDir/tests/input/pipeline/phenotype_single.txt"
    phenotypes_columns = 'Y1'
    covariates_filename = "$baseDir/tests/input/pipeline/covariates.txt"
    nparts_gcta = 3
    batch_subset_prefix = "$baseDir/tests/input/pipeline/test_batch"
    batch_subset_number = 3
}
```

**Resource Override**:
```groovy
process {
    withName: '.*' {
        cpus = 1
        memory = 1.GB
    }
}
```

All processes use minimal resources for fast testing.

---

### development.config

**Purpose**: Development profile with reduced resources for iterative development

**Resource Allocation**:
Balanced resources between test and production:
- Test resources: 1 CPU, 1 GB memory (very fast, minimal overhead)
- Development resources: 1-4 CPUs, 2-8 GB per process (reasonable turnaround)
- Production resources: 8-10 CPUs, 10-16 GB per process (full analysis)

**Key Process Resources**:
```groovy
// Significant processes get 4 CPUs / 6-8 GB
withName: 'REGENIE_STEP1_RUN|GCTA_GRM|LDAK_HE' {
    cpus = { 4 * task.attempt }
    memory = { 6-8.GB * task.attempt }
}

// Light processes get 1 CPU / 1-2 GB
withName: 'ANNOTATE_RESULTS|MERGE_RESULTS' {
    cpus = { 1 * task.attempt }
    memory = { 1.GB * task.attempt }
}
```

**Error Handling**:
```groovy
errorStrategy = 'retry'
maxRetries = 2  // 1 retry (vs 3 in production)
```

Reduced retries speed up development cycle when processes fail.

---

## Entry and Startup

### Inclusion in Main Config
From `nextflow.config`:
```groovy
includeConfig 'conf/base.config'  // Always loaded

profiles {
    test {
        includeConfig 'conf/test.config'  // Loaded with -profile test
    }
}
```

### Profile Activation
```bash
# Load test config
nextflow run main.nf -profile test,singularity

# Use base config only (production)
nextflow run main.nf -profile slurm_singularity
```

---

## External Interfaces

### Parameters Defined

**test.config** sets:
- Input file paths (relative to `$baseDir`)
- Analysis parameters (phenotype columns, test types)
- LDAK-specific parameters (batch subsets)
- Resource minimums for CI/CD

**base.config** does NOT set parameters, only process resources.

---

## Key Dependencies and Configuration

### Dependent Processes
All processes in `modules/local/` and `workflows/` read resource allocations from these configs.

### Configuration Precedence
1. Command-line parameters (`--param value`)
2. Custom config files (`-c custom.config`)
3. Profile configs (`-profile test`)
4. `nextflow.config` defaults
5. `conf/base.config` defaults

### Dynamic Resource Allocation
```groovy
cpus = { 10 * task.attempt }
memory = { 16.GB * task.attempt }
```

**Behavior**:
- Attempt 1: 10 CPUs, 16 GB
- Attempt 2 (after failure): 20 CPUs, 32 GB
- Attempt 3: 30 CPUs, 48 GB

---

## Data Models

### Resource Configuration Structure
```groovy
process {
    withName: 'PROCESS_NAME' {
        cpus = <value>
        memory = <value>
        time = <value>
    }

    withLabel: label_name {
        cpus = <value>
        memory = <value>
        time = <value>
    }

    // Global settings
    errorStrategy = 'retry'
    maxRetries = 3
}
```

### Parameter Structure
```groovy
params {
    // Required inputs
    project = 'string'
    genotypes_association = 'glob_pattern'
    genotypes_prediction = 'glob_pattern'
    phenotypes_filename = 'file_path'

    // Optional inputs
    covariates_filename = 'file_path' | null
    phenotypes_columns = 'col1,col2'

    // Tool-specific
    nparts_gcta = integer
    regenie_bsize_step1 = integer
}
```

---

## Testing and Quality

### Test Data Characteristics
- **Genotypes**: 500 samples, 2 chromosomes, ~1000 variants each
- **Phenotypes**: 1-2 quantitative traits
- **Covariates**: 2-3 covariates (age, sex, PC1)
- **Execution Time**: ~5-10 minutes on local machine

### Validation
```bash
# Verify config loading
nextflow config -profile test

# Check resource allocation
nextflow config -profile test | grep "cpus\|memory"
```

---

## Frequently Asked Questions (FAQ)

**Q: How do I increase memory for a specific process?**
A: Add to your custom config:
```groovy
process {
    withName: 'PROCESS_NAME' {
        memory = 64.GB
    }
}
```
Then run with `-c custom.config`.

**Q: Why do some processes fail with memory errors on retry?**
A: If the process doesn't use `{ ... * task.attempt }` syntax, memory doesn't scale. Update the process config in base.config.

**Q: Can I disable retries?**
A: Yes, in custom config:
```groovy
process {
    errorStrategy = 'finish'  // or 'terminate'
    maxRetries = 0
}
```

**Q: What's the difference between `withName` and `withLabel`?**
A:
- `withName`: Targets specific process by exact name
- `withLabel`: Targets all processes with that label (defined in process module)

**Q: How do I create a new test profile?**
A:
1. Create `conf/mytest.config`
2. Set `params` and minimal `process` resources
3. Add to `nextflow.config`:
   ```groovy
   profiles {
       mytest {
           includeConfig 'conf/mytest.config'
       }
   }
   ```
4. Run with `-profile mytest`

---

## Related File List

- `base.config` - Default resource allocations and retry strategy
- `test.config` - Test profile parameters and minimal resources

---

## Process Resource Summary (base.config)

| Process Group | CPUs | Memory | Notes |
|---------------|------|--------|-------|
| VCF Conversion | 10 | 16 GB | IMPUTED_TO_PLINK* |
| LDAK Kinship | 10 | 10 GB | CALC_KINS_* |
| GCTA GRM | 10 | 10 GB | MAKE_GRM_PART, MERGE_GRM_PARTS |
| REGENIE Step 1 | 8 | 16 GB | Standard and chunked modes |
| REGENIE Step 2 | 8 | 8 GB | Association testing |
| QC/Pruning | 10 | 10 GB | QC_FILTER_GENOTYPED, PRUNE_GENOTYPED |
| Reporting | 1-8 | 1-8 GB | REPORT, ANNOTATE_RESULTS |

All values scale with `task.attempt` for automatic retry resource increase.

---

## Related Documentation

- [Root Documentation](../CLAUDE.md)
- [Workflows](../workflows/CLAUDE.md)
- [Modules](../modules/local/CLAUDE.md)
