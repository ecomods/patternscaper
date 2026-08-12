# CLAUDE.md

Guidance for AI coding assistants working in this repository.

**Read `../_workspace_context/PROJECT_CONTEXT.md` first.** It is the handoff document: what the
project is, how the three repositories relate, the commands, the conventions, and how work should be
delivered. `../_workspace_context/OPEN_WORK.md` is the live worklist and leads with the open
decisions. This file carries only what is dangerous to get wrong before you have read them.

## What this is

`spatPatClassifyR` is an R package that classifies spatial landscape patterns with neural networks.
It generates artificial binary landscapes (`SpatRaster`, 0 = bare ground, 1 = vegetation),
optionally computes landscape metrics, trains a classifier, and applies it to new landscapes,
including real vegetation photographs. It is the software companion to a paper by Baldauf, Tietjen
and Berger, currently in review.

The folder is named `ecotoneClassifyR` while the package is `spatPatClassifyR`. A rename to
`patternClassifyR` is under discussion but not decided.

## Two approaches, kept symmetric

- **Pixel based**: convolutional net via `keras3`. `train_pixel_model()` / `apply_pixel_model()`.
- **Metrics based**: `landscapemetrics` features fed to `neuralnet`. `train_metric_model()` /
  `apply_metric_model()`.

Preserve the `train_*` / `apply_*` crossed with `metric` / `pixel` pairing when adding or renaming.

## The 11 patterns fall into three groups

- **Ecotone**: `sharp`, `diffuse`, `fingers`, `clustered`, `bands`. A vegetated zone and a bare zone
  separated by a transition, placed by `boundary_position`.
- **Patch**, that is self-organized: `spots`, `labyrinth`, `gaps`. No boundary between two zones.
- **Control**: `random`, `bare`, `dense`. No spatial structure at all; they differ only in `veg_prob`.

`vignettes/landscape-generation.qmd` is the authority. Note that the analysis scripts train each
pattern family *together with* the controls, so `ecotone_patterns` there includes `random` and
`selforg_patterns` includes `bare` and `dense`. That is training-set composition, not what the
patterns are. Never describe a control as an ecotone or a self-organized pattern in prose,
documentation or the manuscript.

## Working agreements

- **Do not commit.** Do the work, verify it, propose a commit message, then stop. Selina reviews the
  diff and commits it herself.
- **Small steps.** One reviewable change at a time. Stop for review rather than delivering a whole
  approved batch in one go.
- **Sequence by blast radius.** Everything that cannot change results first, then changes that move
  only error paths, then anything that moves a published number. Results-changing items are
  decisions for Selina, not tasks: a moved number means re-running the analysis repository and
  checking the manuscript tables.
- **No em dashes**, anywhere: code, docs, commit messages, replies. Use colons, commas, parentheses
  or a second sentence.
- **Prefer the simple design.** The package has no external users yet, so breaking changes are cheap
  and compatibility shims are dead weight.
- **Roxygen is user-facing.** It says how to use a function, not why it was designed that way.
  Rationale belongs in `../_workspace_context/DECISIONS_ARCHIVE.md`.

## The loop

```r
devtools::load_all()
devtools::document()   # after any roxygen or export change
devtools::test()       # the primary gate
```

Then, whenever a change could have moved results:

```r
source("dev/golden/check.R")             # metrics within 1e-8, pixel within 1e-5
source("dev/golden/check_landscapes.R")  # exact, no tolerance
```

`devtools::check()` is slow because examples and vignettes are heavy; use
`devtools::check(vignettes = FALSE)` in the loop. **Never run `pkgdown::build_site()` or
`build_reference()` on a branch**: they write about 79 files into the tracked `docs/`. Use
`pkgdown::check_pkgdown()` instead, which takes seconds and writes nothing.

## The sibling analysis repository

`../spatPatClassifyRanalysis` reproduces the paper's figures and tables against this package's
exported API. **Renaming or changing the signature of an export silently breaks it.** Update its
call sites in the same change.

## Code map

- **Landscape generation**: `landscape_create.R` dispatches by pattern to 11 internal
  `landscape_create_*.R` generators. Public surface is `create_landscape()` and
  `create_landscapes()` only.
- **Parameters**: `pattern_params.R` holds the 11 `pattern_*()` constructors;
  `landscape_parameter_validation.R` holds the single canonical spec table.
- **`landscape` S3 class**: `landscape_class.R`, `landscape_methods.R`, `landscape_utils.R`,
  `landscape_geometry.R`.
- **Metrics**: `metrics.R` computes, `metrics_evaluation.R` ranks and selects.
- **Neural networks**: `nn_metrics.R`, `nn_keras.R`, shared helpers in `nn_utils.R`.
- **Plotting**: `plot_landscapes.R`, `plot_classification.R`, `plot_metrics.R`, `plot_themes.R`.

## Style

Tidyverse idiom, native pipe `|>`, anonymous functions `\(x)`, `cli::` for all user-facing
messages. R >= 4.1. Match the surrounding style, and consult the `r-coding-style` and
`r-analysis-workflow` skills before generating R code.
