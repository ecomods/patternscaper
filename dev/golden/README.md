# Golden regression harness

A fast "did the results change?" check for refactors, without rerunning the HPC
pipeline. It runs a scaled-down version of both workflows (metrics-based and
pixel-based, mirroring the analysis `classify_ecotones_*` scripts) and compares
the output against a frozen reference.

## Files

- `run_golden.R` — runs the small workflow, returns the values we track.
- `capture.R` — freezes the current results to `reference.rds`.
- `check.R` — re-runs and diffs current results against `reference.rds`.
- `reference.rds` — the frozen reference (created by `capture.R`).

## Usage

Run from the **package root**, in a session where keras/TensorFlow works.

1. **Freeze the baseline** (once, on the known-good `revision-baseline`):
   ```r
   source("dev/golden/capture.R")
   ```
2. **After a refactor**, verify nothing changed:
   ```r
   source("dev/golden/check.R")
   ```
   - Behaviour-preserving change → "results are identical".
   - Intentional change to results → review the diff, then re-run `capture.R` to
     re-bless the reference.

## What is compared

Both workflows are compared **exactly** (metrics table, selected metrics,
accuracies, confusion matrices, and full prediction tables). Keras is reproducible
across sessions on the same machine — verified — so its predictions are compared
exactly too, not just structurally.

## Caveats

- Capture and check on the **same machine** — exact values (neuralnet *and* keras)
  can differ across machines/BLAS/TensorFlow versions. Re-run `capture.R` when you
  switch machines.
