# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`spatPatClassifyR` is an R package for classifying spatial landscape patterns with neural networks.
It generates artificial binary landscapes with defined spatial patterns, optionally computes
landscape metrics, trains a classifier, and applies it to new landscapes. It is the software
companion to a paper (Baldauf, Tietjen & Berger).

**Two classification approaches run in parallel throughout the package** — keep this symmetry when
adding code:

- **Pixel-based** — convolutional net via `keras3`: `train_pixels_model()` / `apply_pixels_model()`.
- **Metrics-based** — landscape metrics (`landscapemetrics`) fed to a `neuralnet`:
  `train_metrics_model()` / `apply_metrics_model()`.

**Sibling analysis repo.** `../spatPatClassifyRAnalysis` reproduces the paper's figures/tables and
depends on this package's exported API. **Renaming or changing the signature of an export can
silently break that repo** — update its call sites in the same change (it can load this package's
local source via its own `dev/use_local_package.R`).

## Dev environment & the loop

- **R ≥ 4.1** (native pipe `|>`, anonymous functions `\(x)`).
- **keras3 / TensorFlow** is required for the pixel side and runs locally (slowly on tiny nets).
- Inner loop after a change:
  1. `devtools::load_all()`
  2. `devtools::document()` — after any roxygen/export change (regenerates `man/` + `NAMESPACE`)
  3. `devtools::test()` — the primary gate; the suite is thorough (testthat edition 3)
- **`devtools::check()` is slow** — vignettes and examples are computationally heavy. Use
  `devtools::check(vignettes = FALSE)` (or skip examples) in the loop, and reserve the *full*
  check for milestones. Don't run the full check casually.

## Code map (`R/`)

- **Landscape generation** — `create_landscape(pattern, ...)` dispatches by `pattern` to a
  `create_landscape_*()` implementation; `create_landscapes()` is the batch wrapper. Landscapes are
  binary `SpatRaster`s (0 = bare ground, 1 = vegetation). Files: `landscape_create*.R`,
  `create_landscape_*.R`.
- **`landscape` S3 class** — constructor `landscape()`, `print`/`plot` methods, setters
  `set_landscape_name()` / `set_landscape_pattern()`, and `set_random_seed()`. Files:
  `landscape_class.R`, `landscape_methods.R`, `landscape_utils.R`, `landscape_parameter_validation.R`.
- **Metrics** — `calculate_landscape_metrics()` computes features; `evaluate_landscape_metrics()`
  assesses / selects them. Files: `metrics.R`, `metrics_evaluation.R`.
- **Neural networks** — metrics-based in `nn_metrics.R`, pixel-based in `nn_keras.R`, shared helpers
  in `nn_utils.R`.
- **Plotting** — `plot_landscape()`, `plot_landscape_list()`, `plot_classified_landscapes()`,
  `plot_metrics()`; shared theme/palette in `plot_themes.R`. Files: `plot_*.R`.
- **Misc** — `utils.R`; package-level docs in `spatPatClassifyR.R`.

**Two pattern sets** recur across the analyses:
- *Ecotones:* `sharp`, `diffuse`, `clustered`, `fingers`, `bands`, `random`
- *Self-organized:* `bare`, `spots`, `labyrinth`, `gaps`, `dense`

## Conventions

- Tidyverse idiom, native pipe `|>`, anonymous functions `\(x)`; `cli::` for user-facing
  messages, warnings, and errors (used throughout).
- **Parallel naming across model families:** `train_*` / `apply_*` × `metrics` / `pixels`. Preserve
  this pairing when adding or renaming functions.
- Match the surrounding R style. Defer to the **`r-coding-style`** (formatting/idiom) and
  **`r-analysis-workflow`** (data/reproducibility) skills — consult them before generating R code.

## Testing

- `tests/testthat/` (edition 3); fixtures in `tests/testthat/fixtures/`, shared setup in
  `helper-fixtures.R`. Run with `devtools::test()`. Pixel/keras tests run locally.
- `dev/` is a scratch folder for development experiments — build-ignored (`.Rbuildignore`), and its
  heavy model artifacts (`*.keras`, `*.h5`) are git-ignored. Nothing there ships in the package.

## Current work

Active revisions are tracked in `../spatPatClassifyR_paper/REVISIONS.md` (the live todo list).
