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

Neither workflow is bit-reproducible, so both numeric comparisons use a
tolerance — but at very different magnitudes, and the categorical parts stay
effectively exact in both:

- **Metrics workflow** — compared with a **tight tolerance of `1e-8`**.
  `neuralnet` and `landscapemetrics` are structurally deterministic, but the
  matrix maths runs through (often multithreaded) BLAS, so the class scores can
  differ by ~1e-16 (one ULP) even between two runs on the same machine. The tight
  tolerance absorbs that; selected metric names, class labels and confusion
  counts are categorical/integer, so a real change there is still caught.
- **Pixel workflow** — compared with a looser **tolerance of `1e-5`** on numeric
  values. Keras predictions drift by ~1e-7 between TensorFlow installations, so a
  tighter comparison fails on every machine switch. Predicted class labels and
  confusion matrices are still effectively exact.

## Caveats

- Switching machines does **not** require a re-capture. Re-run `capture.R` only
  when you intentionally change results.
- Both tolerances hide genuine changes smaller than themselves. A real regression
  moves predictions far more, but keep it in mind when a change is expected to be
  numerically tiny (below `1e-8` for metrics, `1e-5` for pixels).
