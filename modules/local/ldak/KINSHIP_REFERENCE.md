# LDAK Kinship Process Reference

[LDAK Modules](CLAUDE.md) > **Kinship Calculation Processes**

Detailed reference for LDAK kinship calculation and GRM management processes.

---

## Kinship Calculation Processes

### CALC_KINS_HUMAN

**File**: `calc_kins_human.nf`

**Purpose**: Calculate kinship matrix using LDAK human default model

**Inputs**:
- `tuple val(chr_num), val(filename), path(bed), path(bim), path(fam), val(range)`: PLINK files

**Outputs**:
- `tuple val(chr_num), val(filename), path(...grm.bin), path(...grm.id), path(...grm.details), path(...grm.adjust)`: Kinship files

**Script Logic**:
```bash
ldak6 \
    --calc-kins-direct ${filename} \
    --bfile ${filename} \
    --power -.25 \
    --ignore-weights YES \
    --max-threads ${task.cpus}
```

**Key Parameters**:
- `--calc-kins-direct`: Calculate kinship matrix
- `--power -.25`: LDAK human default model (downweights high-LD SNPs)
- `--ignore-weights YES`: Use power-based weighting instead of pre-computed weights

**Methodology**: Consult **LDAK skill** for detailed explanation of power -.25 model.

**publishDir**: `${params.pubDir}/ldak`

---

### CALC_KINS_UNIFORM

**File**: `calc_kins_uniform.nf`

**Purpose**: Calculate kinship matrix with uniform (equal) SNP weighting

**Inputs**: Same as CALC_KINS_HUMAN

**Outputs**: Same as CALC_KINS_HUMAN

**Script Logic**:
```bash
ldak6 \
    --calc-kins-direct ${filename} \
    --bfile ${filename} \
    --power 0 \
    --ignore-weights YES \
    --max-threads ${task.cpus}
```

**Key Parameters**:
- `--power 0`: Uniform weighting (equivalent to GCTA)

**Use Case**: Comparison with standard methods or when LD adjustment is not desired.

---

### CALC_KINS_WEIGHTS

**File**: `calc_kins_weights.nf`

**Purpose**: Calculate kinship matrix using custom SNP weights

**Inputs**:
- PLINK files (same as above)
- `path weights_file`: Custom weights file

**Outputs**: Same as CALC_KINS_HUMAN

**Script Logic**:
```bash
ldak6 \
    --calc-kins-direct ${filename} \
    --bfile ${filename} \
    --weights ${weights_file} \
    --max-threads ${task.cpus}
```

**Key Parameters**:
- `--weights <file>`: User-provided SNP weights (from thinning or custom)

**Use Case**: LDAK-Thin model or custom weighting schemes.

---

### CALC_KINS_META

**File**: `calc_kins_meta.nf`

**Purpose**: Calculate kinship matrix for meta-analysis

**Status**: TBD (implementation details to be documented)

---

### THIN_PREDICTORS

**File**: `thin_predictors.nf`

**Purpose**: Perform LD-based predictor thinning

**Inputs**:
- PLINK files

**Outputs**:
- `tuple val(chr_num), val(filename), path("${filename}.thin.in")`: Thinned predictor list

**Script Logic**:
```bash
ldak6 \
    --thin ${filename} \
    --bfile ${filename} \
    --window-prune 0.98 \
    --max-threads ${task.cpus}
```

**Key Parameters**:
- `--thin`: Perform LD-based thinning
- `--window-prune 0.98`: Keep predictors explaining <98% of variance

**Output Files**:
```
<filename>.thin.in    # List of retained predictors
```

**Methodology**: Consult **LDAK skill** for thinning algorithm details.

---

### CREATE_THIN_WEIGHTS

**File**: `create_thin_weights.nf`

**Purpose**: Generate SNP weights from thinned predictors

**Inputs**:
- `tuple val(chr_num), val(filename), path(thin_file)`: Thinned predictor list

**Outputs**:
- `path "${filename}.weights"`: Weights file

**Script Logic**:
```bash
# Custom R or shell script to create weights
# Assigns weight=1 to thinned predictors, weight=0 to others
awk '{print $1, 1}' ${thin_file} > ${filename}.weights
```

**Key Notes**:
- Simple binary weighting: included=1, excluded=0
- Used with CALC_KINS_WEIGHTS

---

## GRM Management Processes

### ADD_GRMS

**File**: `add_grms.nf`

**Purpose**: Combine multiple kinship matrices into single matrix

**Inputs**:
- `path mgrm_file`: Multi-GRM file listing kinship prefixes
- `path grm_files`: All kinship files (.bin, .id, .details, .adjust)
- `val combined_grm_name`: Name for combined kinship

**Outputs**:
- `tuple val(combined_grm_name), path(...grm.bin), path(...grm.id), path(...grm.details), path(...grm.adjust)`: Combined kinship

**Script Logic**:
```bash
ldak6 \
    --add-grms ${combined_grm_name} \
    --mgrm ${mgrm_file} \
    --max-threads ${task.cpus}
```

**Key Parameters**:
- `--add-grms`: Combine multiple kinships (typically across chromosomes)
- `--mgrm`: Multi-GRM file

**Use Case**: Combining per-chromosome kinships into genome-wide kinship.

---

### MAKE_MGRM_LDAK

**File**: `make_mgrm_ldak.nf`

**Purpose**: Create multi-GRM file listing kinship matrix prefixes

**Inputs**:
- `path grm_prefixes`: List of GRM prefix strings
- `val mgrm_name`: Name for multi-GRM file

**Outputs**:
- `path "${mgrm_name}.mgrm"`: Multi-GRM file

**Script Logic**:
```bash
echo "${grm_prefixes.join('\n')}" > ${mgrm_name}.mgrm
```

**Key Notes**:
- Plain text file, one prefix per line
- Used by ADD_GRMS and LDAK_REML

---

### FILTER_RELATEDNESS

**File**: `filter_relatedness.nf`

**Purpose**: Remove related individuals from kinship matrix

**Inputs**:
- `tuple val(combined_grm_name), path(grm_bin), path(grm_id), path(grm_details), path(grm_adjust)`: Kinship matrix

**Outputs**:
- `tuple val(filtered_name), path(...keep), path(...lose), path(...maxrel)`: Filtering lists

**Script Logic**:
```bash
ldak6 \
    --filter ${filtered_name} \
    --grm ${combined_grm_name} \
    --max-rel 0.05 \
    --max-threads ${task.cpus}
```

**Key Parameters**:
- `--filter`: Output filtering lists
- `--max-rel 0.05`: Remove individuals with kinship > 0.05 (approximately 2nd-degree relatives)

**Output Files**:
```
<filtered_name>.keep     # Individuals to keep
<filtered_name>.lose     # Individuals to remove
<filtered_name>.maxrel   # Maximum relatedness per individual
```

**Use Case**: Quality control before REML/HE to avoid bias from relatedness.

---

## Related Documentation

- [LDAK Modules Overview](CLAUDE.md)
- [Heritability Process Reference](HERITABILITY_REFERENCE.md)
- [QC Process Reference](QC_REFERENCE.md)
- [LDAK Workflows](../../../workflows/ldak/CLAUDE.md)
