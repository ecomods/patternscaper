# Review — `spatPatClassifyR` (unified)

A single, **priority-ordered** worklist consolidating three review passes. Work it
**top to bottom**: 🔴 High → 🟠 Medium → 🟡 Low. Within each tier, correctness-of-behaviour
items come before API/robustness, then docs/infra/style/tests.

Each item lists location(s), the observation, a suggested fix, and which reviewers raised
it: **[Claude]** (first pass), **[ChatGPT]** (second pass), **[Fable]** (third pass).
Items whose title is prefixed **[Fable]** are findings only the third pass raised.
The original topic-based IDs (e.g. *§1.1*, *ChatGPT §A*, *F1*) are kept in brackets for
traceability.

> Passes: Claude + ChatGPT 2026-07-05; Fable 2026-07-05. Not yet triaged by the maintainer.

---

## 🔴 High — likely wrong behaviour or a user-facing error; fix before release

*All resolved — see **Completed** at the bottom (H1, H2, H3).*

---

## 🟠 Medium — real inconsistency, latent bug, methodological issue, or maintainability risk

### M3. `create_landscapes()` failure bookkeeping is fragile (trailing failures misreported as full success)  — [Claude] [Fable] *(§1.4 / F5)*
`R/landscape_create.R:452-474`. On failure the code does `all_landscapes[[i]] <- NULL`, which
**removes** the element rather than reserving a slot. For a **trailing** failure the list
simply stays short, so `n_failed <- sum(sapply(..., is.null))` (`:462`) counts only interior
`NULL` gaps → `0`, and the function prints *"Successfully generated all N …"* while returning
fewer than N. Interior failures happen to be back-filled with `NULL` by a later assignment, so
only trailing failures are misreported.
- **Effect:** silent under-delivery of the requested sample size, with a message that says
  everything is fine; downstream code assuming `length(landscapes) == n` is misled.
- **Fix:** preallocate (`vector("list", n)`) or track success/failure with an explicit
  counter/logical vector, and compare `length(result)` to `n_requested` for the success/warn
  decision. (Fable rated this 🟡 given retries make failures rare; kept 🟠 per Claude because
  the wrong success message is user-facing.)

### M5. [Fable] Multi-class pixel input fed to the CNN as ordinal integers (no one-hot / no normalization)  — [Fable] *(F2)*
`R/nn_keras.R:187-208`. `train_pixel_model()`/`apply_pixel_model()` build the model input as
the raw raster array (`terra::as.array` → `abind::abind`, `:207`). The docstring
(`nn_keras.R:9-11`, `:505-507`) advertises "0/1/2 for three types". For 3+ categories this
feeds a single channel of **ordinal** integers, so class `2` is numerically twice class `1` —
a semantically wrong, unnormalized encoding for categorical habitat types. **Harmless for the
shipped binary 0/1 case** (0/1 is already a fine scale), so this is not a bug for the paper's
experiments, but the documented 3-class path is statistically unsound.
- **Fix:** either (a) restrict/validate input to binary and drop the 3-class claim, or
  (b) one-hot categories into channels before `abind` (channels = n_classes).

### M6. [Fable] Fold accuracy/loss read from hardcoded keys that break if `metrics` is customized  — [Fable] *(F3)*
`R/nn_keras.R:364,380-381`. The CV loop assumes the keras `evaluate()` result is keyed exactly
`"accuracy"`/`"loss"`. But `metrics` is user-facing (`:112`, documented `:40-42` to accept
`"categorical_accuracy"`, `"top_k_categorical_accuracy"`). If the user passes anything other
than `"accuracy"`, `evaluation[["accuracy"]]` is `NULL`, `round(NULL, 4)` is `numeric(0)`,
`accuracies` becomes a list of `NULL`s, and `mean(accuracies)`/`sd(accuracies)` (`:387`) errors
— a documented option crashes CV.
- **Fix:** derive the key from the compiled metric name (first non-`"loss"` element of
  `evaluation`, or look up by the user's `metrics[1]`) and guard against a missing key.

### M7. `create_landscapes()` silently fails for `gaps` if the user supplies `invert_landscape`  — [ChatGPT] [Fable] *(ChatGPT §A)*
`R/landscape_parameter_validation.R:179-185` allows `invert_landscape` for `gaps`, but
`R/landscape_create_gaps.R:38-46` does **not** accept that argument (it hardcodes `TRUE`
internally). In the batch path, merged params flow through `do.call(create_landscape, ...)` →
`create_landscape_gaps(...)`, so `params_list = list(gaps = list(invert_landscape = FALSE))`
triggers an unused-argument error, which `try_create_landscape()`
(`R/landscape_create.R:541-563`) swallows — the user sees only generic retry/failure messages.
Fable confirmed. A real silent-failure path, beyond the drift in L10.
- **Fix:** either accept `invert_landscape` in `create_landscape_gaps()` or remove it from the
  `gaps` spec; and surface the underlying error (see M12).

### M8. Invalid pattern names are silently dropped in `create_landscapes()`  — [ChatGPT] [Fable] *(ChatGPT §D)*
`R/landscape_create.R:234-248` uses `patterns <- intersect(patterns, valid_patterns)`. A mix of
valid and invalid names silently ignores the invalid ones (only the all-invalid case errors).
Fable confirmed.
- **Effect:** typos can quietly change the requested class set and distort the pattern
  distribution.
- **Fix:** warn or abort on unknown entries instead of silently dropping them.

### M9. `radius_noise_fraction` is unavailable through `create_landscapes()` for spots/gaps  — [ChatGPT] [Fable] *(ChatGPT §E / §2.5)*
`radius_noise_fraction` is a formal argument of `create_landscape_spots()` /
`create_landscape_gaps()` (`R/landscape_create_spots.R:81`, `R/landscape_create_gaps.R:44`) but
is absent from `get_valid_param_specs()` and from `create_landscapes()`'s default param lists.
Fable confirmed.
- **Effect:** users cannot control this documented parameter through the batch generator; it's
  treated as unknown input and removed during validation. (A concrete instance of the drift in
  L10 / M13 — worth fixing directly.)

### M10. `apply_metric_model()` has no `verbose`; `apply_pixel_model()` does  — [Claude] *(§2.1)*
`R/nn_metrics.R:379-383` has no `verbose` parameter and **hardcodes `verbose = TRUE`** when
evaluating performance (`:572`), so it always prints a confusion matrix. `apply_pixel_model()`
(`R/nn_keras.R:558-563`) exposes `verbose` and threads it through.
- **Fix:** add `verbose` to `apply_metric_model()` and pass it down, matching the sibling.

### M11. Inconsistent return shape when `return_performance = TRUE`  — [Claude] [ChatGPT] *(§2.2)*
`apply_pixel_model()` always returns `list(predictions, performance)` (performance may be
`NULL`); `apply_metric_model()` returns a **bare tibble** in some branches (unknown classes,
`R/nn_metrics.R:550`) and a **list** in others (`:576-579`). Downstream
(`plot_classified_landscapes`, the analysis repo) can't rely on a stable shape.
- **Fix:** pick one contract and apply it to both. **[ChatGPT] nuance:** the docs already say
  metrics returns predictions-only when classes are unknown, so treat this as an API-design
  inconsistency rather than a pure correctness bug.

### M12. Generation failures are swallowed with no cause surfaced  — [Claude] *(§3.1)*
`R/landscape_create.R:541-564`. `try_create_landscape()` catches **every** error and returns
`NULL`; the user sees only generic "Retry k/3 … Failed …". A genuinely broken parameter combo
is indistinguishable from bad luck (and hides M7).
- **Fix:** capture and (at least in verbose mode) report `conditionMessage(e)`.

### M13. Parameter definitions are duplicated in three places  — [Claude] *(§3.2)*
Per-pattern parameter knowledge lives in (a) each `create_landscape_*()` signature/defaults,
(b) `create_landscapes()`'s `default_params_list` (`R/landscape_create.R:255-307`), and
(c) `get_valid_param_specs()` (`R/landscape_parameter_validation.R:130-193`). They already
disagree (see M9, L10).
- **Fix:** a single canonical spec (types, bounds, sampling defaults) that all three derive
  from — prevents this whole class of drift.

### M17. Add regression tests for the correctness bugs above  — [Claude] *(§7.1)*
Specifically: (H1) `theme_landscape()` applies a minimal base (panel background ≠ grey);
(M2) `frequency` varies across a batch of generated bands/labyrinth landscapes;
(M3) `create_landscapes()` reports correct success/fail counts on a trailing failure.

---

## 🟡 Low — polish, docs, style, small consistency wins

### L3. [Fable] Metrics classifier is least-squares regression to one-hot targets; `confidence` is uncalibrated post-hoc softmax  — [Fable] *(F6)*
`R/nn_utils.R:515-523`, `R/nn_metrics.R:255-259,495-499`. `fit_nn_model()` calls `neuralnet()`
with **no** `linear.output`/`err.fct`/`act.fct` (a repo-wide grep confirms none), so it runs
with defaults `linear.output = TRUE`, `err.fct = "sse"`: fit by least squares against 0/1
one-hot columns with linear output units — a regression, not a cross-entropy classifier. Raw
outputs are unbounded reals, converted to "probabilities" via a manual softmax and reported as
`confidence`/per-class probabilities.
- **Effect:** (1) argmax classification still works (accuracy meaningful), but the
  `confidence`/probability columns (plotted as "predicted (0.87)") are **not calibrated
  probabilities** — softmax of arbitrary linear scores; (2) SSE-to-one-hot is a weaker
  objective than cross-entropy, so the metrics model likely under-performs (relevant if the
  paper compares metric- vs pixel-based accuracy).
- **Fix:** either set `linear.output = FALSE` (bounded logistic outputs) and document/justify
  the objective, or explicitly document that `confidence` is a relative score, not a calibrated
  probability. At minimum make the choice deliberate.

### L4. [Fable] Pixel model's "k-fold" test silently runs LOO — the k-fold path is never exercised  — [Fable] *(F7)*
`tests/testthat/test-nn_keras.R:106-124`. `test_that("train_pixel_model works with
cv_method='k-fold'")` uses 12 landscapes (4/class) with `cv_folds = 3`, but
`validate_cv_params()` (`R/nn_utils.R:163-171`) computes `max_suitable_folds =
floor(4/3) = 1 < 2`, so it **switches to LOO** (`cv_folds = 12`). The test only asserts output
structure, which LOO satisfies — it passes while testing the wrong branch; genuine k-fold
stratification has no passing pixel-side coverage.
- **Fix:** use ≥9 samples/class (or lower `min_samples_per_fold` for the test), and assert
  `model$performance$cv_method == "k-fold"` and `cv_folds == 3` to pin the branch.

### L5. [Fable] `fisher_score` poisoned to `NA` by any single-sample pattern  — [Fable] *(F8)*
`R/metrics_evaluation.R:341-379`. Within-group variance (`:371-372`) uses
`(group_stats$n - 1) * group_stats$sd_val^2`. For a pattern with one landscape,
`sd_val = sd(<one value>) = NA`, and `0 * NA = NA` (not `0`), making `within_var` `NA` → **every
metric's Fisher score `NA`**. `dplyr::arrange(desc(NA))` then returns the input order, so
`method = "fisher_score"` silently returns a meaningless ranking with no warning.
`rank_by_kruskal()` (`:402-405`) and `rank_by_linear_model()` (`:274-280`) guard with
`tryCatch`; `fisher_score` doesn't. Low incidence in the balanced `create_landscapes()`
pipeline, but `evaluate_metrics()` accepts arbitrary user metrics.
- **Fix:** treat single-member groups as zero within-group contribution (drop them from the
  `sd` term or coerce `NA` sd to 0), and/or wrap the per-metric computation in `tryCatch` like
  the sibling methods.

### L7. Single-landscape handling differs between the two `apply_*`  — [Claude] *(§2.3)*
`apply_pixel_model()` explicitly wraps a lone `landscape` into a list (`R/nn_keras.R:591-593`);
`apply_metric_model()` leans on `calculate_metrics()`. Make both do the same explicit wrap
*(verify both accept a single `landscape` identically)*.

### L9. Default parameters drift between single generators and the batch wrapper  — [Claude] *(§2.5)*
E.g. gaps `n_spots = 15` in `create_landscape_gaps()` vs `c(5, 10)` in `create_landscapes()`;
`invert_landscape` in the spots default list but not gaps; `radius_noise_fraction` a generator
arg but absent from `get_valid_param_specs()` (see M9). See M13 — a single source of truth would
prevent this.

### L10. Rotation silently ignored for most patterns  — [Claude] *(§3.3)*
Only `c("sharp","diffuse","fingers","clustered","bands")` (`R/landscape_create.R:392-398`) honour
`rotation`; for the others it's silently dropped. Document in `create_landscapes()` (and ideally
warn if a non-zero rotation is set for a pattern that ignores it).

### L17. `sapply()` where `vapply()` is safer  — [Claude] [ChatGPT] *(§5.3)*
`R/nn_keras.R` (several), `R/nn_utils.R`, `R/plot_*`. `sapply()` can silently return a list or
matrix; `vapply()` with a template is the package-dev norm. **[ChatGPT]:** low priority — don't
prioritize ahead of concrete user-facing bugs.

### L19. Inconsistent source-file naming  — [Claude] *(§5.5)*
`create_landscape_bare.R` / `create_landscape_dense.R` vs the rest `landscape_create_*.R`, with
dispatcher `landscape_create.R`. Pick one convention (e.g. `create_landscape_*.R`) and rename
for discoverability.

### L21. Empty README badge block  — [Claude] *(§6.3)*
`README.Rmd:18-19` / `README.md:6-8`. Consider lifecycle / R-CMD-check / test-coverage /
(eventual) CRAN badges.

### L22. Pin the `apply_*` return contract with tests  — [Claude] *(§7.2)*
Once M11 is resolved, add tests asserting the return **shape** of both `apply_*` under
`return_performance = TRUE/FALSE`, with and without known classes — the surface the sibling
analysis repo depends on.

### L23. Tests missing for several user-facing mismatches  — [ChatGPT] [Fable] *(ChatGPT §F)*
No tests seen for: `theme_landscape()` composition (H1); plotting classification with unknown
classes / missing `actual_class` (H3); the `gaps + invert_landscape` batch failure (M7); the
`frequency` sampling for bands (M2). Extends M17.

### L24. `plot_classified_landscapes(only_misclassified = TRUE)` aborts when nothing is misclassified  — [Fable]
`R/plot_classification.R`. When a model classifies every landscape correctly (e.g. the ecotone
metrics use case now reaches 100% accuracy after M2), the misclassified-only branch has an empty set
and the function aborts with *"No misclassified landscapes found."* A zero-misclassification result
is a legitimate (good) outcome, not an error — but it breaks a clean `source()` of
`classify_ecotones_metrics.R` / `make.R` in the analysis repo. Surfaced while re-running the use
cases after M2.
- **Fix:** handle the empty case internally — emit an informative `cli` message (e.g. "All
  landscapes classified correctly — nothing to plot") and return gracefully (invisible `NULL` or an
  empty plot) instead of aborting.

---

## Suggested first batch (highest value, lowest risk)

1. `theme_landscape()` composition — **H1** (visible, isolated, testable).
2. Vignette `exclude_na` → `exclude_NA_metrics` — **H2** (user-facing error).
3. Remove `LazyData: true` — **M16** — and flesh out `Description:` — **M14** (pre-submission hygiene).
4. Repair `frequency` integer sampling — **M2** (affects training-data quality).
5. Fold-internal scaling — **M1** (removes CV leakage before any headline numbers are quoted).
6. Add `verbose` to `apply_metric_model()` + unify `apply_*` return shape — **M10 / M11**.

---

## Appendix — areas Fable verified as clean (reporting the negatives)

Checked against current source; correct as-is, no action needed:

- **`kruskal_effsize`** (`metrics_evaluation.R:429`): `H / ((n^2-1)/(n+1))` = `H/(n-1)`, standard
  epsilon-squared (matches rstatix). Correct.
- **`fisher_score` formula** (`metrics_evaluation.R:365-374`): the between/within construction is
  the one-way ANOVA F-statistic — a valid ranking. Only the single-sample edge case is fragile
  (see L5); the formula itself is sound.
- **Confusion-matrix orientation** (`nn_utils.R:320-340`): with `table(Predicted, Actual)`,
  recall = `diag/colSums`, precision = `diag/rowSums` are correctly oriented.
- **terra resample / extent / CRS** (`nn_keras.R:656-669`): template inherits `ext()`/`crs()`
  from source and resamples `method = "near"`, preserving categorical 0/1; the CNN only consumes
  the array, so raster extent is irrelevant to prediction. Clean.
- **Seeding** (`nn_utils.R:28-42`): `set_random_seed()` seeds both R and keras/TF; CV fold
  assignment and keras fit are reproducible. (The scaling issue in M1 is a methodological leak,
  not an RNG one.)
- **`abind` memory** (`nn_keras.R:207`): stacking `n` H×W×1 arrays is O(n·H·W) (~80 MB at
  n=1000, 100×100) — acceptable at the package's stated scales.

---

## Completed

### H1. `theme_landscape()` never composes the base theme  — [Claude] [ChatGPT] [Fable] *(§1.1)*
*Fixed 2026-07-06.* `R/plot_themes.R` evaluated `theme_minimal(...)` and `%+replace%` as discarded
bare statements and returned only the `theme()` overrides, so landscapes sat on ggplot's grey
`theme_grey` default. Now composed into a single `theme_minimal(...) %+replace% theme(...)`
expression (with `%+replace%` imported); regression test added in `tests/testthat/test-plot_themes.R`
asserting the composed theme is complete. `devtools::test()` green.

### H2. Vignette documents a parameter that doesn't exist (`exclude_na`)  — [Claude] *(§1.2)*
*Fixed 2026-07-06.* `vignettes/classify-metrics.qmd` told users not to set `exclude_na = FALSE`, but
the real `evaluate_metrics()` argument was `exclude_NA_metrics` (`R/metrics_evaluation.R:62`), so
copying the callout raised an "unused argument" error. Corrected the name in the vignette. (The
argument itself was later renamed to `exclude_incomplete_metrics` — see L8.)

### H3. `plot_classified_landscapes()` mishandles unlabeled predictions  — [ChatGPT] [Fable] *(ChatGPT §B)*
*Fixed 2026-07-06.* Both `apply_*` always emit `actual_class` (NA or the `"unclassified"` sentinel
for unlabeled input), so the column guard never fired; the real defect was the title `case_when()`
(`R/plot_classification.R`), which had only `predicted == actual` / `!=` branches — for `NA`
actual_class both are `NA` and every title fell through to `"no title"`. Added a leading
`is.na(actual_class) | actual_class == "unclassified"` branch that renders a predicted-only title,
plus a test asserting the rendered titles in `tests/testthat/test-plot_classification.R`.
`devtools::test()` green. (Note: `only_misclassified = TRUE` on unlabeled data still aborts with "No
misclassified landscapes found" — reasonable, since misclassification is undefined without labels.)

### M1. [Fable] Feature scaling is fit on the full dataset before CV → optimistic leakage  — [Fable] *(F1)*
*Fixed 2026-07-06.* `train_metric_model()` scaled predictors once on all landscapes
(`R/nn_metrics.R`) and cross-validated over the already-scaled data, so each fold's validation rows
contributed to the `center`/`scale` applied to them (validation→training leakage biasing CV
accuracy/F1). The CV loop now slices the unscaled `predictors` directly and scaling is fit **inside
each fold** on the training rows only, via a new internal `scale_fold()` helper (`R/nn_utils.R`) that applies the
training center/scale to the validation rows and guards columns constant within a fold (`sd = 0` →
`scale = 1`, no `NaN`). The final deployment model keeps full-data scaling, so `scaling_params`, the
final model, and all `apply_metric_model()` output are unchanged; only the reported CV performance
moves. Verified with the golden harness (only `train_confusion` changed; every `apply_*`/pixel value
identical) and re-captured as the new reference. `scale_fold()` unit tests added in
`tests/testthat/test-nn_utils.R`; `dev/leakage_check.R` demonstrates the before/after on a small LOO
run. Full `devtools::test()` green. (Pixel model unaffected — it does not scale.)

### M14. `DESCRIPTION` `Description:` is thin and understates the package  — [Claude] *(§4.1)*
*Fixed 2026-07-06.* Replaced the one-sentence `Description:` with a proper paragraph covering what the
package does, both classification approaches (pixel-based CNN via `keras3`, metrics-based via
`landscapemetrics` + `neuralnet`), and the full generation → metrics → training → application workflow.
Software names single-quoted per CRAN convention; `read.dcf()` parses cleanly.

### M16. `LazyData: true` with no `data/` directory  — [Claude] *(§6.1)*
*Fixed 2026-07-06.* Removed the `LazyData: true` field from `DESCRIPTION`; with no `data/` folder it
produced an `R CMD check` NOTE.

### Documentation batch (L2, L11, L12, L13, L14)  — [Claude] [ChatGPT] [Fable]
*Fixed 2026-07-06.* Pure doc/typo fixes, verified with a clean `devtools::document()`:
- **L14** (`R/spatPatClassifyR.R`): dropped the deprecated `@docType package` tag (roxygen2 ≥ 7.0
  warns on it alongside `"_PACKAGE"`); the warning is now gone.
- **L11** (`R/landscape_create.R`): corrected the documented `rotation` default to `0:360` (was
  `c(0, 45, 90, 135)`).
- **L12** (`R/landscape_class.R`): fixed the `@param params` roxygen — the first `\link` now points to
  `create_landscape` (was `create_landscapes` twice).
- **L2** (`R/landscape_create_gaps.R`): removed the stray `)` in the two `@details` bullets and
  corrected the example comment (gaps = bare patches in vegetation, not the spots description).
- **L13** (`vignettes/spatPatClassifyR.qmd`): fixed the "guidancen" typo and converted the broken empty
  supplementary link to plain text. Restoring the real URL before publication is tracked under
  "Before publication" in `../spatPatClassifyR_paper/REVISIONS.md`.

### Cleanup batch (L1, L6, L15, L16, L18, L20)  — [Claude] [ChatGPT] [Fable]
*Fixed 2026-07-06.* Light code/doc cleanups; `devtools::test()` green (1377 pass):
- **L1** (`R/nn_metrics.R`): dropped the `type = "raw"` argument from the `apply_metric_model()`
  prediction call — `neuralnet::predict.nn` has no such argument (silently absorbed by `...`).
- **L18** (`R/nn_utils.R`, `R/nn_metrics.R`): extracted the duplicated numerically-stable row-wise
  softmax into a `softmax_rows()` helper, used by both `train_metric_model()` and
  `apply_metric_model()`.
- **L16** (`R/metrics.R`, `R/plot_metrics.R` ×3, `R/plot_landscapes.R`): replaced base `warning()` with
  `cli::cli_warn()`; message text preserved so the existing warning-matching tests still pass.
- **L6** (`R/nn_utils.R`): corrected the `metrics_to_wide()` docstring (class IDs are embedded upstream
  by `calculate_metrics()`, not here) and dropped two unused `@importFrom`s (`rlang::sym`,
  `stringr::str_remove`).
- **L15** (`vignettes/install-keras.qmd`): reworded — `reticulate` is a dependency of `keras3`, not
  installed directly with `spatPatClassifyR`.
- **L20**: already resolved — `.gitignore` contains `tests/testthat/*.pdf` and `Rplots.pdf` is not
  tracked; no change needed.

### M15. `ensure_spatraster()` is dead code and off-convention  — [Claude] [Fable] *(§5.1)*
*Fixed 2026-07-06.* `R/utils.R` defined a single `@noRd` helper `ensure_spatraster()` that nothing
called (grep confirmed no callers in `R/`; `matrix_to_raster()` lives in `landscape_utils.R`, so
deleting the file orphaned nothing). Removed the whole `R/utils.R` file and dropped its mention from
the `CLAUDE.md` code map. No `man/` page (it was `@noRd`) and `NAMESPACE` unaffected (not exported).
`devtools::load_all()` clean; full `devtools::test()` green (0 failures, 1387 pass). No result change.

### M4. `evaluate_metrics()` level check errors on multi-level input & has a misleading message  — [Claude] [Fable] *(§1.5)*
*Fixed 2026-07-06.* The guard at `R/metrics_evaluation.R:85` was
`if (!unique(metrics$level) %in% c("landscape", "class"))` — a length->1 condition when the tibble
carried more than one level (a hard error in R ≥ 4.2), and the abort text mentioned only the
landscape level, contradicting a check that also accepts `"class"`. Split into two guards computed on
`level <- unique(metrics$level)`: `length(level) != 1` aborts cleanly (no R condition-length error)
naming the offending count, and `!level %in% c("landscape", "class")` aborts naming the unsupported
level. Valid single-level input (all the package's own pipeline produces) behaves identically, so no
result change — only error paths differ. Regression test added in
`tests/testthat/test-metrics_evaluation.R` covering both a single unsupported level and a multi-level
tibble. (Note: a *separate* pre-existing flaky test, `verbose parameter controls messaging` at
`:320`, occasionally fails via an unseeded-`rnorm` + `expect_silent()` combo — unrelated to this fix;
flagged for follow-up.)

### M2. `frequency` sampled as an integer, collapsing its declared range  — [Claude] [ChatGPT] [Fable] *(§1.3 / F4)*
*Fixed 2026-07-07.* `"frequency"` was listed in `integer_params` in `create_landscapes()`, so
`sample_landscape_params()` drew it via `seq(from, to, by = 1)`: `bands` (`c(0.1, 0.3)`) collapsed to
a constant `0.1`, and `labyrinth` (`c(2.5, 3.5)`) only ever hit its two endpoints — silently
under-diversifying the training set for both patterns. Three fixes: (1) removed `"frequency"` from
`integer_params` so it is sampled continuously with `runif()`; (2) reconciled the labyrinth
`frequency` spec in `get_valid_param_specs()` from `integer` to `numeric` (bands was already numeric),
so user-supplied fractional frequencies validate consistently with the internal default; (3) hardened
the integer-sampling branch against R's `sample(n)`-means-`sample.int(n)` trap by indexing the
candidate vector explicitly (`int_values[sample.int(length(int_values), 1)]`), so a collapsed integer
range returns its single value instead of a random draw. Regression tests added in
`tests/testthat/test-create-training-landscapes.R` (frequency varies continuously within range for
bands and labyrinth; a collapsed integer range returns the fixed value) — covers the `frequency`
clause of M17. Full `devtools::test()` green (1395 pass); golden check identical (the harness uses no
frequency patterns). Verified end-to-end with a same-machine before/after of the analysis-repo use
cases: only the `bands`/`labyrinth` workflows moved (ecotone-metrics 0.99→1.00, ecotone-pixels
0.79→0.73, selforg-landscape 0.63→0.62, selforg-class 0.94→0.95), all well-formed. Surfaced a
follow-up (L24): `plot_classified_landscapes(only_misclassified = TRUE)` aborts at 100% accuracy.

### L8. `exclude_NA_metrics` breaks the snake_case convention  — [Claude] *(§2.4)*
*Fixed 2026-07-26.* Renamed to `exclude_incomplete_metrics`, which fixes both the naming
convention and an accuracy problem introduced alongside it: the argument now also excludes metrics
that are missing for some landscapes entirely, not just metrics holding `NA` values, so a name
built around `NA` had become misleading. "Incomplete" matches the vocabulary already used by
`remove_incomplete_landscapes()`. Renamed with no deprecation shim — the package is unreleased
(`0.1.0`, no NEWS, no release tags) and nothing outside `R/`, `tests/` and the vignette passed the
argument (the analysis repo never sets it). Updated `vignettes/classify-metrics.qmd` and
regenerated `man/`. Full `devtools::test()` green; golden check identical.
