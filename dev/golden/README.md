# Golden regression harness

A fast "did the results change?" check for refactors, without rerunning the HPC
pipeline. Two independent harnesses live here:

- **Classification harness** (`run_golden.R`/`capture.R`/`check.R`) — runs a
  scaled-down version of both classification workflows (metrics-based and
  pixel-based, mirroring the analysis `classify_ecotones_*` scripts) for 3 of
  the 11 landscape patterns, and compares the output against a frozen
  reference with a tolerance (see below).
- **Landscape-generation harness** (`run_golden_landscapes.R`/
  `capture_landscapes.R`/`check_landscapes.R`) — generates all 11 patterns
  directly (via both `create_landscape()` and `create_landscapes()`) and
  compares the raw matrices/params against a frozen reference **exactly**
  (no tolerance — landscape generation has no BLAS/keras noise). Use this
  whenever a change could plausibly touch landscape generation or the
  parameter-sampling path, even if the classification harness alone would
  pass.

## Files

- `run_golden.R` / `capture.R` / `check.R` / `reference.rds` — classification
  harness (see above).
- `run_golden_landscapes.R` / `capture_landscapes.R` / `check_landscapes.R` /
  `reference_landscapes.rds` — landscape-generation harness (see above).

## Usage

Run from the **package root**, in a session where keras/TensorFlow works (only
needed for the classification harness).

1. **Freeze the baseline** (once, on the known-good `revision-baseline`):
   ```r
   source("dev/golden/capture.R")
   source("dev/golden/capture_landscapes.R")
   ```
2. **After a refactor**, verify nothing changed:
   ```r
   source("dev/golden/check.R")
   source("dev/golden/check_landscapes.R")
   ```
   - Behaviour-preserving change → "results are identical" / "matches the
     reference exactly".
   - Intentional change to results → review the diff, then re-run `capture.R`
     and/or `capture_landscapes.R` to re-bless the reference.

## What is compared

**Classification harness:** neither workflow is bit-reproducible, so both
numeric comparisons use a tolerance — but at very different magnitudes, and
the categorical parts stay effectively exact in both:

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

**Landscape-generation harness:** compared with **no tolerance** —
`waldo::compare()` on the raw matrices/params directly. Landscape generation
is deterministic R with no BLAS/keras involved, so any diff here is a real
change, never numerical noise.

## Caveats

- Switching machines does **not** require a re-capture of the classification
  harness (see tolerances above). The landscape harness is exact and portable
  across machines by construction — no tolerance to worry about there either.
- Re-run `capture.R`/`capture_landscapes.R` only when you intentionally change
  results.
- The classification harness's tolerances hide genuine changes smaller than
  themselves. A real regression moves predictions far more, but keep it in
  mind when a change is expected to be numerically tiny (below `1e-8` for
  metrics, `1e-5` for pixels). The landscape harness has no such blind spot.
