# Review (Fable) — `spatPatClassifyR`

Third-pass review. Goal: (1) find issues the two prior reviewers (see
`REVIEW_PROCESS.md`) did not cover, and (2) re-verify their existing findings against
the current code.

Severity legend (matching `REVIEW_PROCESS.md`):
🔴 High → 🟠 Medium → 🟡 Low.

Written incrementally, best-first within each section.

> Pass started 2026-07-05.

---

## New findings

### 🟠 F1. Feature scaling is fit on the full dataset before CV → optimistic leakage (`nn_metrics.R:182`)

`train_metrics_model()` scales the predictors **once, on all landscapes**, before the
cross-validation loop:

```r
# nn_metrics.R:182
predictors_scaled <- scale(predictors)          # uses ALL rows, incl. every val fold
...
training_data <- data.frame(predictors_scaled, pattern = ...)   # :195
...
for (fold in 1:cv_folds) {                       # :231  CV runs on already-scaled data
  train_data <- training_data[train_indices, ]
  val_data   <- training_data[val_indices, ]
```

The `center`/`scale` used for each fold's validation rows were computed with those same
validation rows included. That is textbook information leakage from validation into
training and makes the reported CV accuracy/F1 (which the paper presumably reports)
mildly optimistic. The pixel model does not scale, so it is unaffected.

**Why it matters:** the CV numbers are the package's headline evidence that the metric
classifier works; a leak biases them upward. Effect is modest for large `n` but real, and
grows for small `n` / LOO — exactly the small-sample regime the package targets.

**Fix:** scale inside the fold — fit `scale()` on `train_data` predictors only, then apply
the stored center/scale to `val_data`. Keep the full-data scaling only for the final
deployment model (that part is correct). Confidence: **High** (leakage is unambiguous;
"how much it inflates" is data-dependent).

### 🟠 F2. Multi-class pixel input is fed to the CNN as ordinal integers (no one-hot / no normalization) (`nn_keras.R:187-208`)

`train_pixel_model()` (and `apply_pixel_model()`) build the model input as the raw raster
array:

```r
# nn_keras.R:187-190
training_arrays <- lapply(landscapes, \(l) terra::as.array(l$data))
# :207
x_data <- abind::abind(training_arrays, along = 0)   # values are the raw cell codes
```

The docstring (`nn_keras.R:9-11`, `:505-507`) explicitly advertises support for
"0/1/2 for three types". For three+ categories this feeds the conv net **ordinal**
integers, so class `2` is numerically twice class `1` in the same single channel — a
semantically wrong encoding for categorical habitat types, and unnormalized. For the
binary 0/1 case (the paper's case) it is harmless because 0/1 is already a fine scale, so
this is not a bug for the shipped experiments — but the documented 3-class path is
statistically unsound.

**Why it matters:** users following the docs on a 3-class raster get a model that treats
categories as magnitudes; results will be arbitrary w.r.t. class labeling.

**Fix:** either (a) restrict/validate input to binary and drop the 3-class claim from the
docs, or (b) one-hot the categories into channels before `abind` (channels = n_classes).
Confidence: **High** that the encoding is ordinal; **Medium** on how much it hurts, since
the shipped analyses are binary.

### 🟠 F3. Fold accuracy/loss are read from hardcoded keys that break if `metrics` is customized (`nn_keras.R:364,380-381`)

The CV loop assumes the keras `evaluate()` result is keyed exactly `"accuracy"`/`"loss"`:

```r
# nn_keras.R:364
"Fold {fold}/{cv_folds} accuracy: {round(evaluation[['accuracy']], 4)}"
# :380-381
accuracies <- sapply(cv_evaluation, \(x) x$evaluation[["accuracy"]])
losses     <- sapply(cv_evaluation, \(x) x$evaluation[["loss"]])
```

But `metrics` is a user-facing argument (`nn_keras.R:112`, documented at `:40-42` to
accept `"categorical_accuracy"`, `"top_k_categorical_accuracy"`). If the user follows the
docs and passes anything other than `"accuracy"`, `evaluation[["accuracy"]]` is `NULL`,
`round(NULL, 4)` is `numeric(0)`, and `accuracies` becomes a list of `NULL`s so the
downstream `mean(accuracies)`/`sd(accuracies)` at `:387` errors out. So a documented
option crashes CV.

**Why it matters:** a documented, plausible parameter choice breaks the primary training
path with an opaque error.

**Fix:** don't hardcode the key — derive it from the compiled metric name (e.g. take the
first non-`"loss"` element of `evaluation`, or look up by the user's `metrics[1]`), and
guard against a missing key. Confidence: **Medium-High** (depends slightly on keras3's
exact naming of the default `"accuracy"` key, which the default path relies on; the break
for non-default metrics is certain).

### 🟠 F4. `bands` `frequency` range collapses to its lower bound — a declared parameter range is silently dead (`landscape_create.R:284,353`)

> **Not new — independently confirms REVIEW_PROCESS §1.3.** Kept for the extra verification
> detail below (the unvalidated-default asymmetry), which their write-up does not spell out.

`create_landscapes()` lists `frequency` in `integer_params`:

```r
# landscape_create.R:344-356
integer_params <- c("n_clusters", ..., "frequency", "octaves", "amplitude")
```

and the `bands` defaults declare a **fractional** frequency range:

```r
# landscape_create.R:284
frequency = c(0.1, 0.3),
```

In `sample_landscape_params()` the integer branch samples from
`seq(from = param_range[1], to = param_range[2], by = 1)` (`landscape_create.R:508-511`).
For `c(0.1, 0.3)` that is `seq(0.1, 0.3, by = 1)` → **`0.1` only**: the upper end of the
range is unreachable, so every `bands` landscape produced by `create_landscapes()` uses
`frequency = 0.1`. `create_landscape_bands()` uses it as
`amplitude * sin(frequency * x)` (`landscape_create_bands.R:123`), so the intended
variation in wave frequency never happens.

The same mechanism hits `labyrinth`'s `frequency = c(2.5, 3.5)`
(`landscape_create.R:302`): `seq(2.5, 3.5, by = 1)` yields `{2.5, 3.5}` only — the interior
of the range is never sampled. (And `get_valid_param_specs()` at `:187` declares labyrinth
`frequency` as `integer`, contradicting the fractional default — a user passing
`frequency = c(2.5, 3.5)` via `params_list` would be *rejected* by
`validate_integer_param()`, while the internal default sails through unvalidated.)

**Why it matters:** the generated training set is less diverse than the code's own
declared ranges imply, which biases what the classifiers learn to recognize as "bands"
/ "labyrinth". It is silent — no error, no warning.

**Fix:** remove `frequency` from `integer_params` (it is genuinely continuous), and
reconcile the `labyrinth`/`bands` `frequency` specs in `get_valid_param_specs()` to
`numeric`. Reserve integer sampling for genuinely discrete counts. Confidence: **High**
(the `seq(..., by = 1)` collapse is deterministic and verified).

### 🟡 F5. Trailing landscape-generation failures are miscounted and misreported as full success (`landscape_create.R:452-474`)

> **Not new — independently confirms REVIEW_PROCESS §1.4.** Verified the exact mechanism
> (trailing vs interior failures) below.

When a landscape fails all retries, the code does:

```r
# landscape_create.R:456-458
} else {
  all_landscapes[[i]] <- NULL     # no-op if i is beyond current list length
}
```

Assigning `NULL` to `list[[i]]` does not create a placeholder; for a **trailing** failure
(the last requested landscapes fail and no later success extends the list) the list simply
stays short. Then:

```r
# landscape_create.R:462-474
n_failed <- sum(sapply(all_landscapes, is.null))   # counts only interior NULL gaps
...
if (n_failed > 0) { warn } else { cli::cli_alert_success("Successfully generated all {n_requested} ...") }
```

So if, say, `n = 5` and landscape 5 fails, `all_landscapes` has length 4, `n_failed == 0`,
and the function prints *"Successfully generated all 5 training landscapes"* while
returning 4. Interior failures happen to be counted (a later assignment back-fills the gap
with `NULL`), so only trailing failures are misreported — but the success message and the
returned length disagree with no warning.

**Why it matters:** silent under-delivery of the requested sample size, with a message
that actively says everything is fine. Downstream code that assumes `length(landscapes)==n`
(or relies on the reassuring message) is misled.

**Fix:** track failures with an explicit counter/logical vector rather than inferring from
`NULL` gaps, and compare `length(result)` to `n_requested` for the success/warn decision.
Confidence: **High** on the mechanism; **Medium** on frequency of occurrence (retries make
failures rare in practice).

### 🟠 F6. The metrics classifier is trained as least-squares regression to one-hot targets; reported probabilities/`confidence` are uncalibrated post-hoc softmax (`nn_utils.R:515-523`, `nn_metrics.R:255-259,495-499`)

`fit_nn_model()` calls `neuralnet()` with **no** `linear.output`/`err.fct`/`act.fct`:

```r
# nn_utils.R:516-523
neuralnet::neuralnet(
  formula = pattern ~ ., data = data,
  hidden = hidden, threshold = threshold, stepmax = stepmax
)
```

(A repo-wide grep for `linear.output|err.fct|act.fct` returns nothing.) So it runs with
`neuralnet`'s defaults `linear.output = TRUE` and `err.fct = "sse"`: the network is fit by
**least squares against 0/1 one-hot columns with linear output units** — i.e. a
regression, not a cross-entropy classifier. The raw outputs are therefore unbounded reals,
and both training and application convert them to "probabilities" with a manual softmax
(`nn_metrics.R:256-259` and `:496-499`), which is then reported as the `confidence` column
and per-class probabilities.

**Why it matters:** (1) argmax classification still works, so accuracy is meaningful, but
the `confidence`/probability columns the package surfaces (and plots as
"predicted (0.87)") are **not calibrated probabilities** — they are softmax of arbitrary
linear scores and can be driven by negative outputs; a user reading them as confidence is
misled. (2) SSE-to-one-hot is a weaker training objective than cross-entropy for
classification, so the metrics model is likely under-performing its potential — relevant
if the paper compares metric-based vs pixel-based accuracy.

**Fix:** either set `linear.output = FALSE` (bounded logistic outputs) — and ideally
document/justify the objective — or explicitly document that `confidence` is a relative
score, not a calibrated probability. At minimum, make the choice deliberate rather than an
inherited default. Confidence: **High** that defaults are in force and the objective is
SSE/linear; **Medium** on the magnitude of the accuracy impact.

### 🟡 F7. The pixel model's "k-fold" test silently runs LOO, so the k-fold path is never actually exercised (`test-nn_keras.R:106-124`)

`test_that("train_pixel_model works with cv_method='k-fold'")` builds
`helper_create_tiny_training_set(n_per_class = 4)` → 12 landscapes, 4 per class, and asks
for `cv_folds = 3`. But `validate_cv_params()` (`nn_utils.R:163-171`) computes
`max_suitable_folds = floor(min_class_count / min_samples_per_fold) = floor(4/3) = 1`,
which is `< 2`, so it **switches the method to LOO** (`cv_folds = 12`). The test only
asserts output structure (`confusion_matrix` is a table, `accuracy` is double), all of
which LOO satisfies — so the test passes while testing the wrong branch. The genuine
k-fold stratification path (`find_balanced_cv_folds` with multi-sample folds) has no
passing coverage on the pixel side.

**Why it matters:** a regression in the k-fold fold-assignment/aggregation logic for the
pixel model would not be caught. The test name asserts a guarantee it does not provide.

**Fix:** use enough samples per class that 3-fold survives the guardrail (≥9 per class), or
lower `min_samples_per_fold` for the test, and assert `model$performance$cv_method ==
"k-fold"` and `cv_folds == 3` so the branch is pinned. Confidence: **High** (the guardrail
arithmetic is deterministic).

### 🟡 F8. `fisher_score` is poisoned to `NA` by any single-sample pattern, silently degrading the whole ranking (`metrics_evaluation.R:341-379`)

`rank_by_fisher_score()` computes within-group variance as

```r
# metrics_evaluation.R:371-372
within_var <- sum((group_stats$n - 1) * (group_stats$sd_val^2)) /
  (sum(group_stats$n) - nrow(group_stats))
```

For any pattern with a single landscape, `sd_val = sd(<one value>) = NA`, and the term
`(n - 1) * sd_val^2 = 0 * NA = NA` (not `0`). One such group makes `within_var` `NA`, so
**every metric's Fisher score becomes `NA`** (the offending group is present in each
metric's nested data). `dplyr::arrange(desc(NA))` then leaves the metrics in arbitrary
(input) order, so `method = "fisher_score"` silently returns a meaningless ranking with no
warning. `rank_by_kruskal()` (`:402-405`) and `rank_by_linear_model()` (`:274-280`) guard
their per-metric computations with `tryCatch`; `fisher_score` has no such guard.

**Why it matters:** it is on the documented list of selection methods, and unlike the
Kruskal path it fails silently rather than returning `NA` for just the affected metric.
Low-probability in the balanced `create_landscapes()` pipeline (classes are balanced), but
`evaluate_metrics()` accepts arbitrary user metrics.

**Fix:** treat single-member groups as zero within-group contribution (drop them from the
`sd` term or coerce their `NA` sd to 0), and/or wrap the per-metric computation in
`tryCatch(..., error/NA)` like the sibling methods. Confidence: **High** on the `0*NA=NA`
propagation; **Low-Medium** on real-world incidence.

### 🟡 F9. `metrics_to_wide()` docstring claims a renaming it does not do, and imports two unused packages (`nn_utils.R:59-94`)

The roxygen for `metrics_to_wide()` states "Metric names are modified to include class IDs
when applicable (format: `metric_class_id`)" and imports `@importFrom rlang sym` /
`@importFrom stringr str_remove` (`nn_utils.R:60-61`), but the function body does none of
that — the `class`→name folding actually happens upstream in `calculate_metrics()`
(`metrics.R:169-177`). So the docstring describes behavior in the wrong function and the two
imports are dead. Harmless at runtime, but it misleads a maintainer about where the
class-suffix contract lives (which matters because `apply_metrics_model()` at
`nn_metrics.R:417` depends on that suffix format via `gsub("_[^_]+$", "", ...)`).

**Fix:** correct the docstring to say IDs are already embedded by `calculate_metrics()`, and
drop the unused `@importFrom`s. Confidence: **High**.

---

## Different conclusions on existing findings

### 🔁 vs. ChatGPT §B ("`plot_classified_landscapes()` cannot plot unlabeled predictions") — right symptom, wrong mechanism and wrong fix

ChatGPT claims the column requirement at `plot_classification.R:60-66` blocks unlabeled
prediction results, so the vignette's promise (`classify-metrics.qmd:217-220`) that
plotting still works without true classes is unmet. **I disagree on the mechanism.**

Both `apply_*` functions **always** emit an `actual_class` column even when the class is
unknown: `apply_pixel_model()` unconditionally does `predictions$actual_class <-
landscape_pattern` (`nn_keras.R:708`), and `apply_metrics_model()` renames the always-present
`pattern` column (originating in `calculate_metrics()`) to `actual_class`
(`nn_metrics.R:529-532`). A `landscape` object's `pattern` defaults to `NA_character_`
(`landscape_class.R:12`), so the column exists with `NA`/`"unclassified"` values. Therefore
the `all(c(... "actual_class" ...) %in% names(classification))` guard **does not fire** — the
call is accepted and runs.

The real (and milder) defect is in the title logic, not the input guard: the `case_when()`
(`plot_classification.R:141-163`) has only `predicted == actual` and `predicted != actual`
branches and no `is.na(actual_class)` branch. For unlabeled input, `predicted == NA` is `NA`
(not `FALSE`), both branches fail to match, and every title falls through to
`.default = "no title"` — **not** the "show the landscape and the predicted pattern only"
the vignette promises. (If `pattern` is the literal string `"unclassified"`, it's worse: the
red "misclassified" branch fires and prints `Actual: unclassified`.)

So: the finding's *conclusion* (docs/behavior mismatch for unlabeled plotting) is valid, but
the diagnosis ("cannot be passed" / hard requirement) and the implied fix ("relax the column
requirement") are wrong. **Correct fix:** add an `is.na(actual_class) | actual_class ==
"unclassified"` branch to the `case_when` that renders a predicted-only title, and add a
test for it. Confidence: **High** (traced end-to-end through both `apply_*` paths and the
`case_when`).

---

## Confirmations (brief)

Verified against the current source; I agree, nothing to add beyond REVIEW_PROCESS.md:

- **§1.1** `theme_landscape()` never composes the base theme — confirmed. `plot_themes.R:16-20`
  evaluate `theme_minimal(...)` and `` `%+replace%` `` as discarded bare statements; only the
  final `theme(...)` is returned. Real bug (High).
- **§1.3 / §1.4** — confirmed independently; see F4 / F5 above for the verification detail.
- **§1.5** `evaluate_metrics()` level check — confirmed. `metrics_evaluation.R:85`
  `if (!unique(metrics$level) %in% ...)` errors on length-`>1` input (R ≥ 4.2), and the abort
  message ("calculate metrics at the landscape level") contradicts a check that also allows
  `"class"`.
- **§1.6** `apply_metrics_model()` passes `type = "raw"` to `predict.nn`, which has no such
  argument (`nn_metrics.R:489-493`) — confirmed absorbed by `...`; the CV path omits it.
- **§5.1** `ensure_spatraster()` is dead code — confirmed; grep finds the definition
  (`utils.R:8`) and no callers anywhere in `R/`.
- **§5.2** base `warning()` still used — confirmed at `metrics.R:142`, `plot_metrics.R:82,133,150`,
  `plot_landscapes.R:213`.
- **ChatGPT §A** `gaps` + user-supplied `invert_landscape` silent failure — confirmed:
  `get_valid_param_specs()` lists `invert_landscape` for `gaps`
  (`landscape_parameter_validation.R:183-184`) but `create_landscape_gaps()`'s signature
  (`landscape_create_gaps.R:38-46`) does not accept it (it hardcodes `TRUE` internally), so a
  batch param triggers an unused-argument error swallowed by `try_create_landscape()`.
- **ChatGPT §C** `rotation` default doc mismatch — confirmed: roxygen says `c(0, 45, 90, 135)`
  (`landscape_create.R:149`), actual default is `0:360` (`:210`).
- **ChatGPT §D** invalid patterns silently dropped via `intersect()` (`landscape_create.R:248`)
  — confirmed.
- **ChatGPT §E** `radius_noise_fraction` unavailable through the batch generator — confirmed:
  it is a formal arg of `create_landscape_gaps()` (`landscape_create_gaps.R:44`) but absent
  from `get_valid_param_specs()`.

### Areas I checked and found clean (calibration items — reporting the negatives)

- **`kruskal_effsize` numerics** (`metrics_evaluation.R:429`): `H / ((n^2-1)/(n+1))`
  algebraically equals `H/(n-1)`, the standard epsilon-squared (matches rstatix). Correct.
- **`fisher_score` formula** (`metrics_evaluation.R:365-374`): the between/within construction
  is the one-way ANOVA F-statistic — a valid discrimination ranking. Only the single-sample
  edge case is fragile (see F8); the formula itself is sound.
- **Confusion-matrix orientation** (`nn_utils.R:320-340`): with `table(Predicted, Actual)`,
  recall = `diag/colSums` and precision = `diag/rowSums` are correctly oriented. Correct.
- **terra resample / extent / CRS path** (`nn_keras.R:656-669`): the template inherits
  `ext()` and `crs()` from the source raster and resamples with `method = "near"`, preserving
  categorical 0/1 values; no CRS/extent mismatch. The CNN only consumes the array, so the
  raster extent is irrelevant to prediction. Clean.
- **Seeding** (`nn_utils.R:28-42`): `set_random_seed()` seeds both R (fold sampling, landscape
  generation) and keras/TF (weight init, dropout); CV fold assignment and keras fit are
  reproducible under it. No leak found here (the scaling *statistical* leak in F1 is a
  separate methodological issue, not an RNG one).
- **`abind` memory** (`nn_keras.R:207`): stacking `n` H×W×1 arrays is O(n·H·W) doubles
  (~80 MB at n=1000, 100×100) — acceptable for the package's stated scales; not a concern
  until much larger `n`.
