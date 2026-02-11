# Repository Guidelines

## Project Structure & Module Organization
- `main.nf` is the pipeline entry point; `nextflow.config` and `nextflow_schema.json` define profiles and parameter validation.
- `workflows/` contains DSL2 workflow orchestration (e.g., `workflows/ldak/`, `workflows/regenie/`).
- `modules/local/` houses process modules used by workflows; keep modules small and reusable.
- `bin/` stores helper scripts (R/Java/Bash); `lib/` contains Groovy utilities.
- `conf/` defines resource profiles; `tests/` holds nf-test cases and `tests/input/` data.
- `docs/` documents analysis types and usage; `work/` and `results/` are runtime/output directories.

## Build, Test, and Development Commands
- Build containers:
  - `singularity build nf-gwas.sif nf-gwas.def`
  - `docker build -t nf-gwas .`
- Run with test data: `nextflow run main.nf -profile test,singularity`.
- Development runs (resume enabled): `nextflow run main.nf -profile development,singularity`.
- HPC runs: `nextflow run main.nf -profile slurm,singularity` (or `slurm_with_scratch`).
- Tests:
  - All: `nf-test test`
  - Single test: `nf-test test tests/modules/local/regenie_step1.nf.test`
  - Local parallel (adaptive shards): `scripts/test-parallel.sh`
  - Local parallel main guards: `scripts/test-parallel-main.sh`
  - Local parallel with manual shard count: `scripts/test-parallel.sh --shards 4`

## Coding Style & Naming Conventions
- Use Nextflow DSL2 syntax; keep processes isolated with explicit inputs/outputs.
- Follow existing formatting (4-space indentation in `.nf`/`.groovy`).
- Process names are uppercase with underscores (e.g., `REGENIE_STEP1_RUN`).
- Channel/file naming uses suffixes: `_ch`, `_file`, `_list`.
- Optional file inputs should be passed as empty lists (`[]`) rather than placeholder paths.
- When adding parameters, update `nextflow_schema.json` and profile defaults in `conf/`.

## Process Implementation Guidance
- Keep `script:` sections in processes short and focused; avoid long inline shell logic.
- Prefer calling a single primary program per process script whenever possible.
- Before implementing new logic, check existing workflows/modules and reuse/adapt them when they already serve a similar purpose.

## Handling Optional Inputs (Ternary File Pattern)
**Required**: Use the ternary file pattern for optional file inputs. Never use placeholder filenames.
```groovy
workflow {
    // Correct: use empty list [] for missing optional files
    covariates_file = params.covariates_filename
        ? file(params.covariates_filename, checkIfExists: true)
        : []
}
```

**Optional tuple element (GRM root) pattern**:
```groovy
process EXAMPLE {
    input:
    tuple val(name), path(grm_bin), path(grm_id), path(grm_details), path(grm_adjust), path(grm_root)
}

workflow {
    // For unadjusted GRMs, append [] so tuple arity stays consistent
    grm_with_root = grm_input.map { t -> t.size() == 5 ? (t + [ [] ]) : t }
}
```

## Testing Guidelines
- Use nf-test; name tests `*.nf.test` to mirror the module/workflow under test.
- Place new module tests in `tests/modules/local/`; workflow tests in `tests/main.nf.test` or `tests/workflows/...` as needed.
- Prefer synthetic or public data; do not include sensitive data in tests or logs.
- For local parallel execution, use `scripts/test-parallel.sh` (default `test,singularity` profile).
- To quickly run only pipeline guard coverage in parallel, use `scripts/test-parallel-main.sh`.
- If a parallel shard fails, rerun the printed `nf-test test --shard i/n` command from `tmp/nf-test/parallel/<timestamp>/summary.txt`.
- **Test input layout**:
  - Shared inputs used by multiple workflows live in `tests/input/`.
  - Each workflow keeps symlinks to shared inputs under `tests/input/{workflow_name}/`.
  - If multiple modules in a workflow share an input, keep it in `tests/input/{workflow_name}/` (or a symlink there) and symlink it into `tests/input/{workflow_name}/{module_name}/`.
  - Module-specific inputs live in `tests/input/{workflow_name}/{module_name}/`.
  - The main pipeline tests (not a workflow) should reference shared inputs directly from `tests/input/`.

## Workflow Review & Test Checklist
- Review new/changed workflows and their modules for input/output correctness (including optional input handling).
- If any implementation detail is unclear, pull upstream docs and save them under `docs/` (prefer `docs/external/<tool>/`) before proceeding.
- Run development test runs for the workflow(s) to capture expected outputs.
- Write/update nf-test workflow and module tests based on the observed output content (avoid file-existence-only assertions).
- Verify the new/updated tests with `nf-test test ... --profile test,singularity`.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits (examples in history): `feat: ...`, `refactor: ...`, `test(gcta): ...`.
- Use optional scopes for workflows/modules: `feat(ldak): ...`.
- PRs should include a short summary, affected workflows, any new/changed params, and test commands run.
- Update documentation (`README.md`, `docs/`) when behavior or inputs change.

## Configuration & Safety Notes
- Tune resources in `conf/base.config` via labels (`process_low`, `process_medium`, `process_high`).
- Prefer containerized runs (Singularity/Docker) for reproducibility.
- Share logs or reports only after scrubbing sensitive data.

## Container Policy for New Programs
- When implementing a new feature that introduces a new program/tool dependency, always add that program to container definitions (`nf-gwas.def`, `Dockerfile`, and/or `environment.yml` as appropriate).
- After adding a new program dependency, always rebuild the relevant container image(s) before considering the feature implementation complete.


## Skills
A skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills that can be used. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.
### Available skills
- skill-creator: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Codex's capabilities with specialized knowledge, workflows, or tool integrations. (file: /home/andongni/.codex/skills/.system/skill-creator/SKILL.md)
- skill-installer: Install Codex skills into $CODEX_HOME/skills from a curated list or a GitHub repo path. Use when a user asks to list installable skills, install a curated skill, or install a skill from another repo (including private repos). (file: /home/andongni/.codex/skills/.system/skill-installer/SKILL.md)
### How to use skills
- Discovery: The list above is the skills available in this session (name + description + file path). Skill bodies live on disk at the listed paths.
- Trigger rules: If the user names a skill (with `$SkillName` or plain text) OR the task clearly matches a skill's description shown above, you must use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.
- Missing/blocked: If a named skill isn't in the list or the path can't be read, say so briefly and continue with the best fallback.
- How to use a skill (progressive disclosure):
  1) After deciding to use a skill, open its `SKILL.md`. Read only enough to follow the workflow.
  2) When `SKILL.md` references relative paths (e.g., `scripts/foo.py`), resolve them relative to the skill directory listed above first, and only consider other paths if needed.
  3) If `SKILL.md` points to extra folders such as `references/`, load only the specific files needed for the request; don't bulk-load everything.
  4) If `scripts/` exist, prefer running or patching them instead of retyping large code blocks.
  5) If `assets/` or templates exist, reuse them instead of recreating from scratch.
- Coordination and sequencing:
  - If multiple skills apply, choose the minimal set that covers the request and state the order you'll use them.
  - Announce which skill(s) you're using and why (one short line). If you skip an obvious skill, say why.
- Context hygiene:
  - Keep context small: summarize long sections instead of pasting them; only load extra files when needed.
  - Avoid deep reference-chasing: prefer opening only files directly linked from `SKILL.md` unless you're blocked.
  - When variants exist (frameworks, providers, domains), pick only the relevant reference file(s) and note that choice.
- Safety and fallback: If a skill can't be applied cleanly (missing files, unclear instructions), state the issue, pick the next-best approach, and continue.
