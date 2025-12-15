# AI Usage Guidelines

Best practices for using AI assistance with the nf-gwas pipeline.

[Root Documentation](../CLAUDE.md)

---

## When to Use AI Assistance

### Recommended Use Cases

1. **Parameter Tuning**
   - Interpreting `nextflow_schema.json` definitions
   - Understanding default values and ranges
   - Optimizing resource allocation for specific datasets

2. **Error Diagnosis**
   - Understanding Nextflow execution errors
   - Analyzing retry failures
   - Debugging process script issues
   - Interpreting tool-specific error messages (REGENIE, GCTA, LDAK)

3. **Workflow Optimization**
   - Suggesting parallelization strategies
   - Identifying bottlenecks
   - Optimizing channel operations
   - Reducing memory/CPU usage

4. **Test Development**
   - Creating new nf-test cases
   - Generating test data
   - Writing snapshot assertions
   - Debugging test failures

5. **Documentation**
   - Generating usage examples
   - Creating workflow diagrams
   - Writing module documentation
   - Updating CLAUDE.md files

6. **Code Refactoring**
   - Identifying code duplication (DRY violations)
   - Suggesting modularization opportunities
   - Improving code readability
   - Applying Nextflow best practices

---

## Context to Provide to AI

### For Error Diagnosis

**Essential Information:**
```bash
# 1. Full error log
cat .nextflow.log | tail -100

# 2. Relevant process script
cat modules/local/regenie/regenie_step1_run.nf

# 3. Input channel structure
# Example: "Channel contains: [chr_num, filename, bed, bim, fam]"

# 4. Expected vs. actual output
# Example: "Expected .regenie file, got empty output"

# 5. Execution environment
nextflow -version
# Profile used: -profile slurm_singularity
```

**Helpful Context:**
- Nextflow version
- Execution profile (local, docker, slurm, etc.)
- Container type (Docker vs. Singularity)
- Resource allocations (CPUs, memory)
- Dataset characteristics (N samples, N variants)

### For Workflow Development

**Provide:**
- Existing workflow structure
- Input data format
- Desired output format
- Performance requirements
- Similar existing workflows for reference

### For Testing

**Include:**
- Test data characteristics
- Expected behavior
- Current test failure output
- Relevant process/workflow code

---

## AI Limitations

### What AI Cannot Do Well

1. **GWAS-Specific Biological Interpretation**
   - AI may not understand latest GWAS methodologies
   - Statistical genetics interpretations may be outdated
   - Consult primary literature for biological conclusions

2. **Tool-Specific Parameter Changes**
   - REGENIE, GCTA, LDAK may have updated parameters
   - Always verify against official documentation
   - Check tool version compatibility

3. **Runtime Optimization Without Profiling Data**
   - Cannot optimize memory/CPU without actual runtime stats
   - Provide real profiling data for accurate recommendations
   - Use Nextflow's execution report: `-with-report`, `-with-timeline`

4. **Security and Privacy**
   - Do not share real patient data or sensitive information
   - Use synthetic or public test data for examples
   - Anonymize paths and project names when possible

5. **Complex Debugging Without Logs**
   - AI needs detailed error logs for diagnosis
   - Vague descriptions lead to generic advice
   - Always provide full stack traces and error messages

---

## Best Practices for AI Interaction

### 1. Reference Documentation First

Before asking AI:
- Check main `CLAUDE.md` in root directory
- Review module-specific CLAUDE.md files
- Consult tool documentation (REGENIE, GCTA, LDAK)
- Search existing GitHub issues

AI is a **supplement**, not a replacement for documentation.

### 2. Provide Minimal Reproducible Examples

**Good Request:**
```
I'm getting this error when running REGENIE Step 1:

Error: No valid phenotypes found

My phenotype file has this structure:
IID FID Y1
001 001 1.5
002 002 NA

Command used:
nextflow run main.nf -profile test

Relevant process: regenie_step1_run.nf:45-60
```

**Bad Request:**
```
REGENIE doesn't work, help!
```

### 3. Specify Nextflow Version and Execution Profile

Always include:
```bash
nextflow -version
# Profile: -profile slurm_singularity
# Container: nf-gwas.sif (Singularity)
```

### 4. Iterate and Validate

- Test AI suggestions before implementing
- Validate outputs against known good results
- Run tests after AI-suggested changes
- Document what worked and what didn't

### 5. Update Documentation

**After resolving issues with AI help:**
- Update relevant CLAUDE.md with findings
- Add to FAQ sections
- Document workarounds or edge cases
- Share solutions in GitHub issues

---

## Common AI-Assisted Tasks

### Task 1: Understanding Parameter Schemas

**Query:**
```
What does the parameter --regenie_gene_build_masks do?
See nextflow_schema.json:line 450
```

**Expected AI Response:**
- Explanation of mask building in gene-based tests
- How it interacts with --regenie_gene_masks
- Example usage
- Reference to REGENIE documentation

### Task 2: Optimizing Resource Allocation

**Query:**
```
REGENIE Step 1 is running out of memory (16 GB).
Dataset: 500K samples, 1M variants
Current config: conf/base.config:line 85

How should I adjust resources?
```

**Expected AI Response:**
- Analysis of memory requirements
- Suggested memory allocation formula
- Chunking strategy if needed
- Example configuration update

### Task 3: Creating New Tests

**Query:**
```
I need to create an nf-test for ldak_he.nf workflow.
Test data: tests/input/pipeline/example.{bed,bim,fam}
Expected output: .he file with heritability estimate

Reference existing test: tests/modules/local/ldak_reml.nf.test
```

**Expected AI Response:**
- Complete nf-test template
- Proper channel structure
- Snapshot assertions
- Documentation comments

### Task 4: Error Diagnosis

**Query:**
```
Process CALC_KINS_HUMAN fails with:
Error: kinship matrix is not positive semi-definite

Log: work/ab/cd1234/.command.err
Input: 500 samples, chr22 only
Config: default from base.config
```

**Expected AI Response:**
- Explanation of error (related individuals, QC issues)
- Suggested QC steps (--maf, --geno filters)
- Alternative kinship calculation methods
- Links to LDAK documentation

---

## LDAK-Specific AI Guidance

For questions about LDAK methods, theory, or command-line usage, the **LDAK skill** provides comprehensive documentation covering all LDAK functionality.

**When to use LDAK skill:**
- Understanding LDAK theoretical background (kinship models, weighting schemes)
- Command-line syntax questions
- Parameter explanations
- Troubleshooting LDAK-specific errors

**LDAK skill includes:**
- Detailed heritability estimation documentation
- Genetic correlation methods
- Quality control procedures
- All LDAK analysis workflows

**In this pipeline's context**, focus on:
- How LDAK integrates with Nextflow workflows
- Parameter mapping from LDAK CLI to pipeline params
- Output interpretation in pipeline context

---

## AI Code Review Checklist

Before implementing AI-suggested code:

- [ ] Code follows Nextflow DSL2 syntax
- [ ] Proper error handling (`errorStrategy`, `maxRetries`)
- [ ] Resource allocation uses `task.attempt` scaling
- [ ] Process has meaningful `tag` for logging
- [ ] Input/output channels properly structured
- [ ] `publishDir` configured correctly
- [ ] Code follows project style (see [CODING_STANDARDS.md](CODING_STANDARDS.md))
- [ ] Tests created/updated for new code
- [ ] Documentation updated (CLAUDE.md)
- [ ] No hardcoded paths or credentials
- [ ] Container compatibility verified

---

## Requesting CLAUDE.md Updates

**At the end of every major coding task or significant refactor**, ask:

> "Should we update CLAUDE.md with any new architectural findings from this work?"

This ensures documentation stays synchronized with codebase changes.

**What to document:**
- New workflows or processes
- Changed parameter behaviors
- Performance optimizations discovered
- Common error resolutions
- Integration patterns
- Testing strategies

---

## Example AI Conversation Flow

### User Request
```
I want to add a new LDAK workflow for multivariate GREML.
Where should I start?
```

### AI Response (Good)
```
1. First, let's check if LDAK supports multivariate GREML:
   - Review LDAK skill documentation
   - Check ldak6 --help for relevant commands

2. Create workflow structure:
   - New file: workflows/ldak/ldak_multivariate_greml.nf
   - Reference existing: workflows/ldak/ldak_reml.nf (lines 1-50)

3. Required process modules:
   - Likely needs: modules/local/ldak/ldak_reml.nf (modify for multivariate)
   - May need new process for multi-phenotype input handling

4. Add to main workflow:
   - Include in workflows/nf_gwas.nf
   - Add params to nextflow_schema.json
   - Update nextflow.config with defaults

5. Testing:
   - Create test: tests/workflows/ldak/ldak_multivariate_greml.nf.test
   - Use existing test data: tests/input/pipeline/phenotype.txt (Y1, Y2)

6. Documentation:
   - Update workflows/ldak/CLAUDE.md
   - Update root CLAUDE.md with new workflow entry
   - Add usage example to docs/ANALYSIS_TYPES.md

Would you like me to help with step 1 (LDAK command exploration) or
proceed with step 2 (workflow skeleton)?
```

### User Follow-up
```
Let's start with step 2, create the workflow skeleton.
```

### AI Response
[Provides complete workflow template with comments]

---

## Related Documentation

- [Root Documentation](../CLAUDE.md)
- [Coding Standards](CODING_STANDARDS.md)
- [Analysis Types](ANALYSIS_TYPES.md)
- [Testing Documentation](../tests/CLAUDE.md)

---

## Feedback and Improvement

If AI assistance is:
- **Helpful**: Document the solution in CLAUDE.md for future reference
- **Incorrect**: Report the issue and document the correct approach
- **Incomplete**: Provide missing context and iterate

**Continuous improvement cycle:**
1. Use AI assistance
2. Validate results
3. Document learnings
4. Update guidelines
5. Share with team
