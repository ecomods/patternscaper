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

The two workflows are compared differently, because only one of them is
bit-reproducible:

- **Metrics workflow** — compared **exactly** (metrics table, selected metrics,
  accuracies, confusion matrices, prediction tables). `neuralnet` and
  `landscapemetrics` are deterministic and portable across machines, so any
  difference here is a real change.
- **Pixel workflow** — compared with a **tolerance of `1e-5`** on numeric values.
  Keras predictions drift by ~1e-7 between TensorFlow installations, so an exact
  comparison fails on every machine switch. Predicted class labels and confusion
  matrices are still compared exactly, since the tolerance applies only to
  numbers — a class flip is still caught.

## Caveats

- Switching machines does **not** require a re-capture. Re-run `capture.R` only
  when you intentionally change results.
- The `1e-5` tolerance hides genuine pixel-side changes smaller than that. Any
  real regression in the CNN moves predictions far more, but keep it in mind when
  a change is expected to be numerically tiny.
