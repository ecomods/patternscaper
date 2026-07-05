# Review process — `spatPatClassifyR`

A running log of things that can or should be improved, clarified, or refactored.
Structured **by topic**; within each topic, items are ordered **by priority**
(🔴 High → 🟠 Medium → 🟡 Low).

- 🔴 **High** — likely wrong behaviour or a user-facing error; fix before release.
- 🟠 **Medium** — real inconsistency, latent bug, or maintainability risk.
- 🟡 **Low** — polish, style, docs, and small consistency wins.

Each item lists the location(s), what I observed, and a suggested direction.
Several items are marked *(verify)* where I'm reasonably but not 100% certain and a
quick reproducible check is warranted before acting.

> First review pass — 2026-07-05. Not yet triaged/confirmed by the maintainer.

---

## 1. Correctness & bugs

### 1.1 🔴 `theme_landscape()` never composes the base theme
`R/plot_themes.R:15-38`. The function body evaluates `theme_minimal(...)` and
`ggplot2::\`%+replace%\`` as bare statements and **discards** them; only the final
`ggplot2::theme(...)` is returned. The intended
`theme_minimal(...) %+replace% theme(...)` composition never happens.
- **Effect:** landscapes rendered via `plot.landscape()` / `plot_landscape()` sit on
  ggplot's default grey `theme_grey` background instead of the clean minimal look the
  theme was written to produce. (Axis text/ticks/grid are still blanked because those
  overrides live in the returned `theme()`, which is why it hasn't been obvious.)
- **Fix:** `theme_minimal(base_size, base_family) %+replace% theme(...)` as a single
  returned expression. Add a snapshot/regression test so it can't silently regress again.
- **ChatGPT:** Confirmed. `theme_landscape()` currently evaluates `theme_minimal()` and
  `%+replace%` as separate bare expressions, so `plot.landscape()` ends up adding only the
  final `theme(...)` on top of ggplot's default theme. I agree this is a real bug, not just
  style.

### 1.2 🔴 Vignette documents a parameter that doesn't exist (`exclude_na`)
`vignettes/classify-metrics.qmd` (metric-selection callout) tells users
"It is not recommended to set `exclude_na = FALSE`". The actual argument of
`evaluate_metrics()` is **`exclude_NA_metrics`** (`R/metrics_evaluation.R:62`).
A user copying the vignette hits an "unused argument" error.
- **Fix:** rename in the vignette to `exclude_NA_metrics` (and see 2.4 — consider
  renaming the argument itself to fit snake_case, then the vignette is consistent too).

### 1.3 🟠 `frequency` is treated as an integer parameter, collapsing its range *(verify)*
`R/landscape_create.R:344-356` lists `"frequency"` in `integer_params`, and
`sample_landscape_params()` (`R/landscape_create.R:507-511`) samples integer params via
`sample(seq(from, to, by = 1), 1)`.
- With the bands default `frequency = c(0.1, 0.3)` (`landscape_create.R:284`),
  `seq(0.1, 0.3, by = 1)` is just `0.1` → **bands frequency is effectively constant**.
- With the labyrinth default `frequency = c(2.5, 3.5)` (`landscape_create.R:302`),
  only `2.5` / `3.5` are ever drawn — interior values never appear.
- This quietly reduces the diversity of generated training data.
- **Related latent trap:** `sample(x, 1)` where `seq()` returns a single numeric `>= 1`
  triggers R's "`sample(n)` means `sample.int(n)`" behaviour and returns a *wrong* value.
  Narrow integer ranges are one bad default away from this.
- **Fix:** decide whether `frequency` is genuinely integer (it's declared `integer` for
  labyrinth in `get_valid_param_specs()` but `numeric` in spirit for bands). If it should
  be continuous, drop it from `integer_params`. Replace the `seq()+sample()` idiom with
  `sample(seq.int(...))` for integers and `runif()` for reals, guarding the single-value case.
- **ChatGPT:** Confirmed, and if anything slightly stronger than written. In
  `create_landscapes()`, `frequency` is included in `integer_params`, but in
  `get_valid_param_specs()` it is `numeric` for `bands` and `integer` for `labyrinth`. For
  `bands`, the current default range `c(0.1, 0.3)` collapses to a single sampled value
  (`0.1`) under the current `seq(..., by = 1)` logic.

### 1.4 🟠 `create_landscapes()` failure bookkeeping is fragile
`R/landscape_create.R:452-464`. On failure the code does `all_landscapes[[i]] <- NULL`,
which in R **removes** a list element rather than reserving an empty slot. Combined with
index-based assignment and `names(all_landscapes)[i] <-`, a **trailing** failure leaves no
`NULL` placeholder, so `n_failed <- sum(sapply(..., is.null))` can under-count and the
"Generated x/y" summary can be wrong.
- **Fix:** preallocate (`vector("list", n)`) or collect into a growing list with explicit
  success/failure tracking rather than relying on positional `NULL` assignment.

### 1.5 🟠 `evaluate_metrics()` level check errors on multi-level input & has a misleading message
`R/metrics_evaluation.R:85-89`. `if (!unique(metrics$level) %in% c("landscape","class"))`
uses a length-`>1` condition if `metrics$level` ever contains more than one level (an
error in R ≥ 4.2), and the abort text ("Please calculate metrics at the landscape level")
contradicts the check, which actually *allows* the class level.
- **Fix:** guard with `length(unique(level)) == 1 && level %in% c(...)` and correct the
  message to mention both supported levels.

### 1.6 🟡 `apply_metrics_model()` passes a `type` argument `predict.nn` ignores
`R/nn_metrics.R:489-493` calls `predict(model, newdata = ..., type = "raw")`, but
`neuralnet::predict.nn` has no `type` argument — it's silently absorbed by `...`. The CV
loop (`R/nn_metrics.R:248-253`) omits it, so the two prediction paths look different for
no reason. Drop `type = "raw"` for clarity.

### 1.7 🟡 `create_landscape_gaps()` doc contradicts itself
`R/landscape_create_gaps.R`. The `@details` say gaps = "Bare patches in vegetation", but
the example comment (`gaps_default`) says "vegetation patches in bare ground" (that's
*spots*). There are also stray `)` characters in the two `@details` bullets. Tidy the copy.

---

## 2. API design & cross-family consistency

> The package's defining feature is the **`train_*`/`apply_*` × `metrics`/`pixels`**
> symmetry (per `CLAUDE.md`). The items below are places where that symmetry has drifted.

### 2.1 🟠 `apply_metrics_model()` has no `verbose`; `apply_pixel_model()` does
`R/nn_metrics.R:379-383` has no `verbose` parameter and **hardcodes `verbose = TRUE`**
when evaluating performance (`R/nn_metrics.R:572`), so it always prints a confusion
matrix. `apply_pixel_model()` (`R/nn_keras.R:558-563`) exposes `verbose` and threads it
through. Add `verbose` to `apply_metrics_model()` and pass it down, matching the sibling.

### 2.2 🟠 Inconsistent return shape when `return_performance = TRUE`
- `apply_pixel_model()` always returns a `list(predictions, performance)` (performance may
  be `NULL`).
- `apply_metrics_model()` returns a **bare tibble** in some branches (e.g. unknown classes,
  `R/nn_metrics.R:550`) and a **list** in others (`R/nn_metrics.R:576-579`).
- Callers/downstream (`plot_classified_landscapes`, the analysis repo) can't rely on a
  stable shape. Pick one contract and apply it to both functions.
- **ChatGPT:** Partial disagreement on severity. I agree this is inconsistent with
  `apply_pixel_model()`, but the current `apply_metrics_model()` documentation already says
  that when classes are unknown it returns predictions only. I would call this an API design
  inconsistency rather than a pure correctness bug.

### 2.3 🟡 Single-landscape handling differs between the two `apply_*`
`apply_pixel_model()` explicitly wraps a lone `landscape` into a list
(`R/nn_keras.R:591-593`); `apply_metrics_model()` leans on `calculate_metrics()` to do so.
Make both do the same explicit wrap for predictability *(verify both accept a single
`landscape` object identically)*.

### 2.4 🟡 `exclude_NA_metrics` breaks the snake_case convention
`R/metrics_evaluation.R:62`. Everything else is lowercase snake_case; this one embeds
`NA`. Consider `exclude_na_metrics` (with a deprecation shim if any callers exist). Fixing
this also resolves 1.2 cleanly.

### 2.5 🟡 Default parameters drift between single generators and the batch wrapper
E.g. gaps default `n_spots = 15` in `create_landscape_gaps()` vs `c(5, 10)` in
`create_landscapes()`'s `default_params_list`; `invert_landscape` appears in the spots
default list but not gaps; `radius_noise_fraction` is a `create_landscape_spots`/`_gaps`
argument but absent from `get_valid_param_specs()`. See 3.3 — a single source of truth
would prevent this class of drift.

---

## 3. Landscape generation robustness

### 3.1 🟠 Generation failures are swallowed with no cause surfaced
`R/landscape_create.R:541-564`. `try_create_landscape()` catches **every** error and
returns `NULL`; the user sees only generic "Retry k/3 … Failed …" messages. A genuinely
broken parameter combination is indistinguishable from bad luck. Capture and (at least in
verbose mode) report `conditionMessage(e)`.

### 3.2 🟠 Parameter definitions are duplicated in three places
The same per-pattern parameter knowledge lives in (a) each `create_landscape_*()`
signature/defaults, (b) `create_landscapes()`'s `default_params_list`
(`R/landscape_create.R:255-307`), and (c) `get_valid_param_specs()`
(`R/landscape_parameter_validation.R:130-193`). They already disagree (see 2.5). Consider a
single canonical spec (types, bounds, sampling defaults) that all three derive from.

### 3.3 🟡 Rotation silently ignored for most patterns
Only `patterns_with_rotation <- c("sharp","diffuse","fingers","clustered","bands")`
(`R/landscape_create.R:392-398`) honour `rotation`; for the others it's silently dropped.
Document this in `create_landscapes()` (and ideally warn if a user sets a non-zero rotation
for a pattern that ignores it).

---

## 4. Documentation (roxygen + vignettes)

### 4.1 🟠 `DESCRIPTION` `Description:` is thin and understates the package
`DESCRIPTION:13-16` reads "Classification of landscapes using a neural network." The README
and vignettes are far richer. For an MEE/CRAN-facing package the `Description` field should
be a proper paragraph (what it does, the two approaches, intended use). Low effort, visible
payoff.

### 4.2 🟡 `landscape()` `@param params` links the wrong function twice
`R/landscape_class.R:38-39` says "by the `create_landscapes` or the `create_landscapes`
function" — one should be `create_landscape`.

### 4.3 🟡 Placeholder/typo content in the getting-started vignette
`vignettes/spatPatClassifyR.qmd`: empty link `[supplementary information of the paper]()`
(line ~28) and typo "guidancen" (line ~22). Fill/fix before publication.

### 4.4 🟡 `@docType package` is deprecated with the `"_PACKAGE"` sentinel
`R/spatPatClassifyR.R:36-38`. roxygen2 ≥ 7.0 warns on `@docType package` when `"_PACKAGE"`
is present; drop the `@docType` line.

### 4.5 🟡 `reticulate` described as bundled but not a declared dependency
`vignettes/install-keras.qmd` says reticulate "is installed alongside" the package, but
it's only a transitive dependency of `keras3` (not in `DESCRIPTION`). Either add it to
`Suggests` or reword to "installed with keras3".
- **ChatGPT:** I agree with the diagnosis but only partly with the remedy. The vignette
  wording is wrong, but I do not think adding `reticulate` to `Suggests` is necessary unless
  you want to guarantee examples that directly call `library(reticulate)`. Rewording the
  vignette may be sufficient.

---

## 5. Code style & idiom consistency

### 5.1 🟠 `ensure_spatraster()` is dead code and off-convention
`R/utils.R` defines `ensure_spatraster()` but nothing calls it (confirmed by search). It
also uses `message()` and `class(x)[1] == "SpatRaster"` instead of the package's
`cli::` + `inherits()` idiom. Remove it, or wire it in and modernise.

### 5.2 🟡 Mixed `warning()` vs `cli::cli_warn()`
`CLAUDE.md` states `cli::` is used throughout, but base `warning()` remains in
`calculate_metrics()` (`R/metrics.R:142`), `plot_metrics()` (3×) and `plot_landscapes()`
(`R/plot_landscapes.R:213`). Standardise on `cli::cli_warn()` for user-facing warnings.

### 5.3 🟡 `sapply()` in places where `vapply()` is safer
`R/nn_keras.R` (several), `R/nn_utils.R`, `R/plot_*`. `sapply()` can silently return a list
or matrix on unexpected input; `vapply()` with an explicit template is the package-dev norm.
- **ChatGPT:** Reasonable style note, but low priority. I agree `vapply()` is safer than
  `sapply()`, but I would not prioritize this ahead of the concrete user-facing bugs and
  documentation mismatches.

### 5.4 🟡 Softmax-on-raw-outputs is duplicated
The `t(apply(x, 1, \(r) { e <- exp(r - max(r)); e/sum(e) }))` block appears in both
`train_metrics_model()` (`R/nn_metrics.R:256-259`) and `apply_metrics_model()`
(`R/nn_metrics.R:496-499`). Extract a small `softmax_rows()` helper in `nn_utils.R`.

### 5.5 🟡 Inconsistent source-file naming
Two generators are `create_landscape_bare.R` / `create_landscape_dense.R`; the rest are
`landscape_create_*.R`, and the dispatcher is `landscape_create.R`. Pick one convention
(e.g. `create_landscape_*.R`) and rename for discoverability.

---

## 6. Package infrastructure & metadata

### 6.1 🟠 `LazyData: true` with no `data/` directory
`DESCRIPTION:22`. There is no `data/` folder, so `LazyData: true` produces an
`R CMD check` NOTE ("'LazyData' is specified without a 'data' directory"). Remove the field
(easy pre-submission win).

### 6.2 🟡 Test artifact committed to the repo
`tests/testthat/Rplots.pdf` is a by-product of plot tests. Add to `.gitignore` (and, if
possible, prevent its creation, e.g. by directing device output to a temp file in tests).

### 6.3 🟡 Empty README badge block
`README.Rmd:18-19` / `README.md:6-8` have an empty `badges` block. Consider
lifecycle / R-CMD-check / test-coverage / (eventual) CRAN badges.

---

## 7. Testing

*(Coverage looks broad — every pattern and both NN families have dedicated test files.
The notes below are targeted additions, not a claim of gaps.)*

### 7.1 🟠 Add regression tests for the correctness bugs above
Specifically: (1.1) that `theme_landscape()` actually applies a minimal base (e.g. panel
background is not the grey default); (1.3) that `frequency` varies across a batch of
generated bands/labyrinth landscapes; (1.4) that `create_landscapes()` reports the correct
success/fail counts when a trailing generation fails.

### 7.2 🟡 Pin the `apply_*` return contract with tests
Once 2.2 is resolved, add tests asserting the return **shape** of both `apply_metrics_model`
and `apply_pixel_model` under `return_performance = TRUE/FALSE`, with and without known
classes — this is exactly the surface the sibling analysis repo depends on.

---

## Suggested first batch (highest value, lowest risk)

1. `theme_landscape()` composition fix — **1.1** (visible, isolated, testable).
2. Vignette `exclude_na` → `exclude_NA_metrics` — **1.2** (user-facing error).
3. Remove `LazyData: true` — **6.1** and flesh out `Description:` — **4.1** (pre-submission hygiene).
4. Investigate/repair `frequency` integer sampling — **1.3** (affects training-data quality).
5. Add `verbose` to `apply_metrics_model()` + unify `apply_*` return shape — **2.1 / 2.2**.

---

## ChatGPT additional points Claude seems to have missed

### A. 🟠 `create_landscapes()` can silently fail for `gaps` if user supplies `invert_landscape`
`R/landscape_parameter_validation.R:179-185` allows `invert_landscape` for the `gaps` pattern, but `R/landscape_create_gaps.R:38-46` does **not** accept that argument. In the batch path, merged parameters are passed through `do.call(create_landscape, ...)`, which then calls `create_landscape_gaps(...)` without `...`. So a user-supplied
`params_list = list(gaps = list(invert_landscape = FALSE))`
can trigger an unused-argument error inside `create_landscape_gaps()`. That error is then swallowed by `try_create_landscape()` (`R/landscape_create.R:541-563`), so the user only sees generic retry/failure messages.
- **ChatGPT note:** this is more than the drift noted in 2.5; it is a real silent failure path.

### B. 🔴 `plot_classified_landscapes()` cannot plot unlabeled predictions, despite docs saying it can
`R/plot_classification.R:61-65` requires `classification` to contain `actual_class`, `predicted_class`, `confidence`, and `landscape_id`. But `apply_metrics_model()` and `apply_pixel_model()` can both return prediction outputs without `actual_class` when true classes are unknown, and the vignette explicitly says that plotting should still work in that case (`vignettes/classify-metrics.qmd:217-220`). As written, unlabeled prediction results from the `apply_*` functions cannot be passed to `plot_classified_landscapes()`.
- **ChatGPT note:** I would treat this as a genuine correctness/docs mismatch.

### C. 🟡 `create_landscapes()` documentation gives the wrong default for `rotation`
In `R/landscape_create.R:149`, the roxygen says the default is `c(0, 45, 90, 135)`, but the actual function default at `R/landscape_create.R:210` is `0:360`.
- **ChatGPT note:** user-facing documentation error; small fix, but worth correcting.

### D. 🟠 Invalid pattern names are silently dropped in `create_landscapes()`
`R/landscape_create.R:234-248` uses `patterns <- intersect(patterns, valid_patterns)`. If the user passes a mix of valid and invalid names, the invalid ones are silently ignored; only the all-invalid case errors.
- **Effect:** typos can quietly change the requested class set and distort the pattern distribution.
- **ChatGPT suggestion:** warn or abort on unknown entries instead of silently dropping them.

### E. 🟠 `radius_noise_fraction` is effectively unavailable through `create_landscapes()` for spots/gaps
Claude mentioned the underlying parameter drift in 2.5, but I think the user-facing impact is worth spelling out separately. `radius_noise_fraction` is a formal argument of `create_landscape_spots()` and `create_landscape_gaps()` (`R/landscape_create_spots.R:81`, `R/landscape_create_gaps.R:44`), but it is absent from `get_valid_param_specs()` and from `create_landscapes()`'s default parameter lists.
- **Effect:** users cannot actually control this documented parameter through the batch generator; it will be treated as unknown input and removed during validation.

### F. 🟡 Existing tests do not seem to cover several of the most user-facing mismatches
There are good tests overall, but I do not see tests for:
- the actual composition behavior of `theme_landscape()`;
- plotting classification outputs with **unknown** classes / missing `actual_class`;
- the `gaps + invert_landscape` batch failure path above;
- the `frequency` sampling behavior for `bands`.
- **ChatGPT note:** this supports Claude's testing section, and I would extend it to cover the additional cases above.
