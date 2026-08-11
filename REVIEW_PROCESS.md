# Review — `spatPatClassifyR` (unified)

A single, **priority-ordered** worklist consolidating three review passes. Work it
**top to bottom**: 🔴 High → 🟠 Medium → 🟡 Low. Within each tier, correctness-of-behaviour
items come before API/robustness, then docs/infra/style/tests.

Each item lists location(s), the observation, a suggested fix, and which reviewers raised
it: **[Claude]** (first pass), **[ChatGPT]** (second pass), **[Fable]** (third pass).
Items whose title is prefixed **[Fable]** are findings only the third pass raised.
The original topic-based IDs (e.g. *§1.1*, *ChatGPT §A*, *F1*) are kept in brackets for
traceability.

> Passes: Claude + ChatGPT 2026-07-05; Fable 2026-07-05.
> Triaged and partially worked since. **Last re-verified against the source 2026-08-05**, and again
> **2026-08-10** for the M18–M22 landscape-generation items specifically (all confirmed complete or
> updated below after the 2026-08-06/07 `pattern_*()` constructor rollout — see **Completed**). Items
> marked **[new]** were added at or after the 2026-08-05 re-verification — each carries its own date
> — and did not come from the three original passes.
>
> **Synced 2026-08-11:** L25 and M22 step 2 were both settled on 2026-08-11 but this file still
> listed L25 as an open decision. Both now sit under **Completed**, with L25's outstanding *re-run*
> (not decision) kept in Group C. No landscape-generation code items remain open here; what is left
> for landscape generation lives in `../spatPatClassifyR_paper/REVISIONS.md` under the 2026-08-07
> "Pattern + creation help pages review".

---

## 🔴 High — likely wrong behaviour or a user-facing error; fix before release

*All resolved — see **Completed** at the bottom (H1, H2, H3).*

---

## 🟠 Medium — real inconsistency, latent bug, methodological issue, or maintainability risk

### M5. [Fable] Multi-class pixel input fed to the CNN as ordinal integers (no one-hot / no normalization)  — [Fable] *(F2)*
`R/nn_keras.R:187-208`. `train_pixel_model()`/`apply_pixel_model()` build the model input as
the raw raster array (`terra::as.array` → `abind::abind`, `:207`). The docstring
(`nn_keras.R:9-11`, `:505-507`) advertises "0/1/2 for three types". For 3+ categories this
feeds a single channel of **ordinal** integers, so class `2` is numerically twice class `1` —
a semantically wrong, unnormalized encoding for categorical habitat types.
**Correction 2026-08-10 — this is not just a documented-but-unused risk.**
`../spatPatClassifyRAnalysis/analysis/02_usecases/classify_ecotones_3classes.R:357-374` calls
`train_pixel_model()` directly on landscapes built by `add_third_class()`, which substitutes
real pixels with a third cell value — exactly this scenario, on a real worked-example script,
not a synthetic edge case. Whether that script's numbers reached a published table/figure is
unconfirmed (the script is independently flagged as not yet rerun since an unrelated
API-rename fix — see `../spatPatClassifyR_paper/REVISIONS.md`, "Analysis code"). The "harmless
for the shipped binary case" framing still holds for every *other* pixel-model use case in the
repo (all binary 0/1), so this stays scoped to the one 3-class script — but within that scope
it is confirmed live code, not a theoretical concern.
- **Fix:** either (a) restrict/validate input to binary and drop the 3-class claim, or
  (b) one-hot categories into channels before `abind` (channels = n_classes). Given the
  confirmed usage, (b) is the one that actually fixes `classify_ecotones_3classes.R` rather
  than just removing the claim.

### M6. ~~Fold accuracy/loss read from hardcoded keys that break if `metrics` is customized~~ — **DONE 2026-08-05** (`cf69fb5`)
**Resolved by removing the `metrics` parameter from `train_pixel_model()`**, rather than by making the
key dynamic. It was the only argument that cannot affect the model (keras metrics are monitoring
only), and neither documented alternative was a real choice: measured, `categorical_accuracy` returns
the *identical* value to `"accuracy"` with one-hot targets, and `top_k_categorical_accuracy` at 6
classes asks whether the true class is in the top 5 of 6. The three hardcoded keys are now correct by
construction; `compile_keras_model()`'s own unused `metrics` argument went with it. Nothing in the
package, tests, vignettes or the analysis repo passed it. Original finding below.


`R/nn_keras.R:364,380-381`. The CV loop assumes the keras `evaluate()` result is keyed exactly
`"accuracy"`/`"loss"`. But `metrics` is user-facing (`:112`, documented `:40-42` to accept
`"categorical_accuracy"`, `"top_k_categorical_accuracy"`). If the user passes anything other
than `"accuracy"`, `evaluation[["accuracy"]]` is `NULL`, `round(NULL, 4)` is `numeric(0)`,
`accuracies` becomes a list of `NULL`s, and `mean(accuracies)`/`sd(accuracies)` (`:387`) errors
— a documented option crashes CV.
- **Fix:** derive the key from the compiled metric name (first non-`"loss"` element of
  `evaluation`, or look up by the user's `metrics[1]`) and guard against a missing key.

### M11. Inconsistent return shape when `return_performance = TRUE`  — [Claude] [ChatGPT] *(§2.2)*
`apply_pixel_model()` always returns `list(predictions, performance)` (performance may be
`NULL`); `apply_metric_model()` returns a **bare tibble** in some branches (unknown classes,
`R/nn_metrics.R:550`) and a **list** in others (`:576-579`). Downstream
(`plot_classified_landscapes`, the analysis repo) can't rely on a stable shape.
- **Fix:** pick one contract and apply it to both. **[ChatGPT] nuance:** the docs already say
  metrics returns predictions-only when classes are unknown, so treat this as an API-design
  inconsistency rather than a pure correctness bug.


*M18, M19, M20, M21 and M22 (both steps) are all done — see **Completed** ("M21 + M18 + M19 + M20 +
M22 step 1"), where step 2's resolution by removal is recorded.*


### M24. [new] No `keras3::clear_session()` between models in `train_pixel_model()` — *(added 2026-08-10)*
`R/nn_keras.R:412-418` (CV fold loop) and `:516-522`/`:549-555` (final model, both branches).
Every CV fold, plus the final model, builds a fresh `keras_model_sequential()` via
`create_keras_model()`, but nothing calls `keras3::clear_session()` (confirmed exported by the
installed `keras3`) between them. A single call can construct 2 to `cv_folds` models (up to
`total_samples` under LOO) in one R process with no backend session/graph reset in between — a
known TensorFlow/Keras source of accumulating graph state and memory growth across repeated
model creation in one process.
- **Effect:** unlikely to change model *outputs* — weight initialization is independent of
  session bookkeeping — but a real stability risk on exactly the workload this package is built
  for: the HPC systematic-test script trains in a loop for 8-16h per replicate x 10. Memory
  growth/slowdown here would surface as a stalled or OOM-killed HPC job, not a wrong number, so
  it is easy to miss until it happens. **Caveat (peer-reviewed 2026-08-10):** severity is
  plausible but unverified without profiling — TF2's eager execution doesn't accumulate a graph
  the way TF1 did, so the size of the leak in the currently-installed keras3 version is an open
  question, not a measured fact.
- **Fix:** call `keras3::clear_session()` at the top of each fold iteration and before building
  the final model; pair with `gc()` right after, since R-side collection of the overwritten
  `reticulate` model objects isn't synchronized with Python-side deallocation. Verify with
  `dev/golden/check.R` before/after — not expected to change results, but this resets Keras's
  internal state at exactly the point `set_random_seed()`-driven initialization happens, so
  confirm rather than assume.

### M25. [new] `apply_pixel_model()` skips performance for every landscape if any known-class landscape has an unseen class — *(added 2026-08-10)*
`R/nn_keras.R:897-914`. When `return_performance = TRUE`, the function computes
`unknown_classes <- setdiff(unique_actual, class_names)` across the *whole* known-class
subset; if even one landscape's actual class is unseen by the model, performance evaluation is
skipped for **all** landscapes with known classes, not just the offending one(s) —
`predictions` is still returned, but `performance` comes back `NULL` for the entire batch. Not
a crash, and arguably a deliberate conservative choice, but undocumented: nothing in the
roxygen or the supplement says one unrecognized label voids evaluation of the rest. Related to
**M11** (the `apply_*` return-shape inconsistency) — both concern what `apply_pixel_model()`
actually promises under `return_performance = TRUE`.
- **Fix:** either document the all-or-nothing behavior explicitly, or evaluate performance on
  the subset of landscapes whose actual class *is* known to the model, warning about the rest.

### M26. [new] No validation that raster values are actually categorical — *(added 2026-08-10)*
`R/nn_keras.R` (`train_pixel_model()`, `apply_pixel_model()`). Both the roxygen and the
supplement (§S1.5.2) state the pixel workflow "requires categorical/discrete raster data" and
explicitly reject continuous data such as elevation or gradients — but neither function checks
this. Any raster that passes the NA guard and the dimension guard is accepted, continuous or
not; `terra::as.array()` doesn't care. Moot for package-generated landscapes (always integer
0/1), but the stated requirement is unenforced for user-supplied rasters (e.g. the real-image
worked example, or any external data).
- **Before implementing:** check whether the real-image worked example's raster is stored as a
  strict integer/factor type or as float-typed categorical values — a strict integer check
  could reject currently-working input.
- **Fix:** validate discreteness (e.g. all values are whole numbers, or few unique values) and
  abort with a clear message, once the check above confirms it doesn't break existing use cases.

### M17. Add regression tests for the correctness bugs above  — [Claude] *(§7.1)*
*Done.* (H1) `theme_landscape()`, (M2) `frequency` variation, and (M3, fixed 2026-08-10)
`create_landscapes()` trailing-failure counts all have tests (`test-plot_themes.R`,
`test-create-training-landscapes.R`).

---

## 🟡 Low — polish, docs, style, small consistency wins

### L4. ~~Pixel model's "k-fold" test silently runs LOO — the k-fold path is never exercised~~ — **DONE 2026-08-05** (`e39f716`)
Fixture raised to 9 landscapes per class (the smallest set that keeps `cv_folds = 3`), and the branch
pinned with assertions on `cv_method`/`cv_folds`, one hold-out per landscape across the folds, and
stratified fold composition (3 of every class in every fold). Original finding below.

`tests/testthat/test-nn_keras.R:125-137` (confirmed still open 2026-08-05).
`test_that("train_pixel_model works with cv_method='k-fold'")` uses `n_per_class = 4` with
`cv_folds = 3`, but
`validate_cv_params()` (`R/nn_utils.R:163-171`) computes `max_suitable_folds =
floor(4/3) = 1 < 2`, so it **switches to LOO** (`cv_folds = 12`). The test only asserts output
structure, which LOO satisfies — it passes while testing the wrong branch; genuine k-fold
stratification has no passing pixel-side coverage.
- **Fix:** use ≥9 samples/class (or lower `min_samples_per_fold` for the test), and assert
  `model$performance$cv_method == "k-fold"` and `cv_folds == 3` to pin the branch.

### L5. [Fable] `fisher_score` poisoned to `NA` by any single-sample pattern  — [Fable] *(F8)*
*Still open, description corrected 2026-08-05.* `rank_by_fisher_score()` is now at
`R/metrics_evaluation.R:652-690`. Two parts of the original finding no longer apply: a
`length(unique(df$pattern)) < 2` guard (`:659-661`) catches the *single-group* case, and the
ranking now tie-breaks deterministically (`arrange(desc(score), metric)`, `:686`) rather than
silently returning input order.
**What remains:** the *single-sample-per-group* case. Within-group variance (`:681-682`) still
uses `(group_stats$n - 1) * group_stats$sd_val^2`; for a pattern with one landscape
`sd_val = sd(<one value>) = NA` and `0 * NA = NA` (not `0`), so `within_var` is `NA` → that
metric's Fisher score is `NA`. Low incidence in the balanced `create_landscapes()` pipeline, but
`evaluate_metrics()` accepts arbitrary user metrics.
- **Fix:** treat single-member groups as zero within-group contribution (drop them from the
  `sd` term or coerce `NA` sd to 0), and/or wrap the per-metric computation in `tryCatch` like
  `rank_by_kruskal()`.

### L7. Single-landscape handling differs between the two `apply_*`  — [Claude] *(§2.3)*
`apply_pixel_model()` explicitly wraps a lone `landscape` into a list (`R/nn_keras.R:591-593`);
`apply_metric_model()` leans on `calculate_metrics()`. Make both do the same explicit wrap
*(verify both accept a single `landscape` identically)*.

*Note 2026-08-05:* still open, and it is about the two **`apply_*`** functions only. The related
train-side problem — `train_pixel_model()` reporting a lone landscape's own fields as "Invalid
element(s) at index(es): 1, 2, 3, 4" — was a separate finding, fixed in `a1ec361` by *aborting* with
a clear message rather than wrapping, since training on one landscape is never valid.

### L26. [new] `pkgdown::build_reference()` hard-errors  — *(added 2026-08-05)*
Pre-existing, unrelated to the landscape work: `print.metrics_evaluation` has no entry anywhere
in `_pkgdown.yml`'s reference index, and pkgdown aborts on an unindexed topic. One-line fix,
worth doing before the website work (which M18/M20 will touch anyway).

### L17. `sapply()` where `vapply()` is safer  — [Claude] [ChatGPT] *(§5.3)*
*Partially done 2026-08-05.* `sapply()` can silently return a list or matrix; `vapply()` with a
template is the package-dev norm. **[ChatGPT]:** low priority — don't prioritize ahead of concrete
user-facing bugs.
- **Done:** `R/plot_classification.R` (`c93eac9`), where the same `sapply()` was also being
  evaluated twice.
- **Remaining:** `R/nn_keras.R` (several), `R/nn_utils.R`, and the other `R/plot_*` files.

### L21. Empty README badge block  — [Claude] *(§6.3)*
`README.Rmd:18-19` / `README.md:6-8`. Consider lifecycle / R-CMD-check / test-coverage /
(eventual) CRAN badges.

### L22. Pin the `apply_*` return contract with tests  — [Claude] *(§7.2)*
Once M11 is resolved, add tests asserting the return **shape** of both `apply_*` under
`return_performance = TRUE/FALSE`, with and without known classes — the surface the sibling
analysis repo depends on.

### L27. [new] `train_pixel_model()` silently writes an undocumented `_metadata.rds` file — *(added 2026-08-10)*
`R/nn_keras.R:604-607`. When `model_path` is given, a second file
(`<model_path minus .keras>_metadata.rds`) is written alongside the `.keras` file, holding
everything in the return object except the model itself. Covered by a test
(`tests/testthat/test-nn_keras.R:206-234`) but never mentioned in `@param model_path` or
`@return` — a user saving a model has no documented way to know the second file exists, and
there is no `load_pixel_model()` to reassemble the two. No result impact.
- **Fix:** document the companion file in `@param model_path`, or fold into the existing
  "Website: better guide on how to save and load a Keras model" item.

### L28. [new] Same-dimensions guard checks rows/columns, not layer count — *(added 2026-08-10)*
`R/nn_keras.R:259-278`. The guard added to give a clear error instead of a cryptic `abind()`
failure compares `terra::nrow()`/`terra::ncol()` across training landscapes but not
`terra::nlyr()`. Landscapes of matching width/height but differing layer count would still
reach `abind()`'s raw error. Purely theoretical today — every `create_landscape_*()` generator
emits single-layer rasters — so no result impact, and no in-repo path can trigger it.
- **Fix:** add an `nlyr()` check alongside the existing one, if the guard is meant to fully
  preempt `abind()` failures.

### L29. [new] No per-class minimum-sample check when `cv_method = "none"` — *(added 2026-08-10)*
`R/nn_utils.R`, `validate_cv_params()`. The singleton-class check only runs inside the `"loo"`
branch; `cv_method = "none"` returns early with no check at all, so `train_pixel_model()` (and
`train_metric_model()`, which shares this helper) will silently fit on a class with a single
training example. Not a crash, and every landscape set the package's own generators produce is
balanced, so no result impact — but no warning fires either.
- **Fix:** a low-severity `cli_alert_info()` for very small classes, same style as the existing
  "some classes have few samples" warning already in the k-fold/LOO branches, applied to
  `"none"` too.

### L30. [new] `set_random_seed()` does not guarantee bit-reproducibility on GPU — *(added 2026-08-10, unconfirmed relevance)*
TensorFlow's GPU reduction/convolution ops are non-deterministic by default regardless of
seeding; exact reproducibility on GPU additionally needs
`Sys.setenv(TF_DETERMINISTIC_OPS = "1")` set before `keras3`/`tensorflow` loads. Likely moot
here: `dev/golden/check.R` already verifies pixel predictions bit-reproducible across sessions
on the same machine using only `set_random_seed()`, which would be surprising if GPU were in
play without the extra env var — so CPU-only training is the more likely explanation. Not
independently confirmed either way; flagging so it isn't lost, not asserting it's live.
- **Fix, if GPU turns out to be used:** document the extra env var alongside
  `set_random_seed()`.

---

## Next batch (re-planned 2026-08-05)

The original "first batch" is fully done (H1, H2, M16, M14, M2, M1, M10) — see **Completed**.
Remaining work, grouped by **whether it can change published results**, because that determines
whether the analysis repo has to be re-run:

**Group A — cannot change any result** (docs, messages, tests, file names).
**M18/M19/M20/M21/M22 step 1 done 2026-08-06/07** — see **Completed**.

*Remaining:*
1. ~~**L19**~~ — done 2026-08-10, see **Completed**.
2. **L17** — `sapply()` → `vapply()` (`R/nn_keras.R`, `R/nn_utils.R`, other `R/plot_*` files).
3. **L21** — README badges.

**Group B — changes only error/warning paths, not successful runs.** Existing golden checks
should stay byte-identical; only failure behaviour moves:
6. ~~**M3**~~ — done 2026-08-10, see **Completed**.
7. ~~**M8**~~ — done 2026-08-10, see **Completed**.
8. ~~**M12**~~ — done 2026-08-10, see **Completed**.
9. ~~**M23**~~ — done 2026-08-10, see **Completed**. Also fixed a real bug it surfaced along the
   way: the integer-sampling path could silently draw a fractional value at small landscape sizes.
10. ~~**L24** — `plot_classified_landscapes(only_misclassified = TRUE)` at 100% accuracy.~~ *Done
    2026-08-05, together with the rest of the `plot_classified_landscapes()` batch — see
    **Completed**.*
11. **L7** — single-landscape handling parity between the two `apply_*`.

**Open decisions (not tasks — settle these before the work they gate):**
- ~~**L25**~~ — decided and implemented 2026-08-11; see **Completed**. The analysis re-run it gates
  is still outstanding, and is tracked in Group C below.
- ~~**M22 step 2**~~ — decided 2026-08-11 by *removal*: `noise_veg_to_bare` / `noise_bare_to_veg`
  are gone from the package entirely rather than given a `batch_range`. See **Completed**.
- ~~**L9**~~ — decided and done 2026-08-10; see **Completed**.
- ~~**M21**~~ — decided 2026-08-05, implemented 2026-08-06/07; see **Completed** and
  `../spatPatClassifyR_paper/CHANGELOG.md` (2026-08-06/2026-08-07 entries).

**Group C — will or may change results; needs the analysis re-run and a manuscript check:**
9. **L25** — code done 2026-08-11 (see **Completed**); the **re-run is the outstanding part**.
   Scope and cost are in `../spatPatClassifyR_paper/REVISIONS.md` (`## Code`): self-organized and
   ecotone use cases, the robustness test, image classification, and the HPC sweep.
10. **M11 / L22** — unify the `apply_*` return contract (touches the analysis repo's call sites).
11. **M5** — pixel-model input encoding (ordinal integers for 3+ classes). *(M6 was here too; done
    2026-08-05 by removing the `metrics` parameter, and it changed no results.)*
12. **L5** — `fisher_score` single-sample guard (changes metric ranking when it fires).

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

### L25. `radius_noise_fraction` has no default batch range  — [new]
*Decided and implemented 2026-08-11* (`11d1518`). **The code is done; the analysis re-run it forces
is not, and is tracked in Group C above.** M9's fix had made `radius_noise_fraction` a valid,
settable `params_list` parameter but deliberately left it `batch_range = NULL`, so every
batch-generated spots/gaps landscape in every training and test set used the generator default `0`,
i.e. perfectly sharp circular edges.
**Decision: give it a real `batch_range`,** `c(0, 0.2)` for both `spots` and `gaps`
(`R/landscape_parameter_validation.R`). The reasoning is recorded on the analysis side
(`../spatPatClassifyR_paper/REVISIONS.md`, `## Code`): a batch range that is never reachable
through normal batch generation is a half-implemented feature rather than a deliberate default, so
the package default becomes the realistic (randomized) one, and any script needing the old
deterministic condition sets it explicitly via `params_list` and documents that choice at the call
site.
**This is the one landscape-generation change that does move published numbers.** Self-organized
pattern accuracy will shift, so both golden references (`reference_landscapes.rds` and the
classification harness's `reference.rds`) were re-captured rather than checked. The same commit also
seeds the landscape harness's `single` path independently of the batch path, so that a change to
what the batch samples no longer shifts the RNG stream position the single landscapes start from.
That is a fix to the harness rather than to the package, and it is what makes the two paths
independently interpretable in future diffs.
Decided together with M22 step 2 and originally tracked as a single item; the two halves then went
opposite ways (M22 step 2 was resolved by removing its parameters instead, which changes no raster
and needs no re-run). See **Completed → "M21 + M18 + M19 + M20 + M22 (step 1)"** for that half.

### L10. Rotation silently ignored for most patterns  — [Claude] *(§3.3)*
*Fixed 2026-08-10.* Only `c("sharp", "diffuse", "fingers", "clustered", "bands")` honour
`rotation`; the other six patterns silently dropped it. The doc half was already folded into M19;
this closes the remaining warning half — but scoped to `create_landscape()` only, not
`create_landscapes()` (see below).
**Fix:** `create_landscape()` now warns (`cli::cli_warn()`) when a non-zero `rotation` is
explicitly passed for a pattern outside that set — there, requesting rotation for one specific,
named pattern that doesn't support it is plausibly a real mistake. Uses `missing(rotation)` to
stay silent when `rotation` is left at its default, and when it is explicitly `0`, since nothing
is actually being dropped in either case. `man/create_landscape.Rd` updated to match.
`create_landscapes()` deliberately does **not** warn: mixing rotatable and non-rotatable patterns
under one shared `rotation` is the documented, intended way to build a heterogeneous training set
(the package's own default `patterns` is all 11), so warning there would fire on ordinary,
common calls rather than mistakes — warning fatigue rather than a useful signal. A
`create_landscapes()`-level warning was implemented and tested, then deliberately reverted after
review; the trade-off is that a genuine typo/misunderstanding inside a batch call goes back to
being silently dropped, same as before this fix, but that mistake still surfaces via
`create_landscape()` during interactive exploration. Regression tests in `test-create-landscape.R`
cover the warning firing for each non-rotatable pattern and the landscape value being unaffected
by it; `test-create-training-landscapes.R` pins `create_landscapes()`'s silence, including the
mixed rotatable/non-rotatable case. Verified: `devtools::test()` (0 fail) and
`dev/golden/check_landscapes.R` (byte-exact, all 11 patterns) — no change to any valid-input
output, only what gets printed for a `create_landscape()` input that was already a no-op.
**Aside, out of scope:** `devtools::document()` also regenerated `pattern_gaps.Rd`,
`pattern_spots.Rd`, `pattern_labyrinth.Rd`, and unrelated paragraphs of `create_landscape.Rd` /
`create_landscapes.Rd` (`pattern_label`, `params`, `params_list`) — their roxygen source is
already ahead of the committed `man/` output. Reverted those to keep this change scoped; the
drift itself is pre-existing and untouched.

### L19. Inconsistent source-file naming  — [Claude] *(§5.5)*
*Fixed 2026-08-10.* `create_landscape_bare.R` / `create_landscape_dense.R` were the only two
generator files not following the `landscape_create_*.R` convention used by the other nine (and
by the dispatcher `landscape_create.R`).
**Fix:** renamed both files (`git mv`) to `landscape_create_bare.R` / `landscape_create_dense.R`.
Pure file rename — the `create_landscape_bare()`/`create_landscape_dense()` function names,
exports, and `man/` pages are unchanged, so no `devtools::document()` was needed. Checked
`NAMESPACE`, `DESCRIPTION`, `.Rbuildignore`, `_pkgdown.yml`, tests, and `dev/` for any other
reference to the old *filenames* — none found; the only remaining hits for
`create_landscape_bare`/`create_landscape_dense` are the function names themselves, which did not
change. Verified: `devtools::test()` (2406 pass / 0 fail) and `dev/golden/check_landscapes.R`
(byte-exact, all 11 patterns).

### M3. `create_landscapes()` failure bookkeeping is fragile (trailing failures misreported as full success)  — [Claude] [Fable] *(§1.4 / F5)*
*Fixed 2026-08-10.* `all_landscapes[[i]] <- NULL` on failure removed the element rather than
reserving a slot, so a **trailing** failure left the list short instead of holding an explicit
`NULL` — `n_failed <- sum(sapply(..., is.null))` then counted `0`, and the function reported
*"Successfully generated all N …"* while quietly returning fewer than N.
**Fix:** preallocate `all_landscapes <- vector("list", n)` up front, and drop the explicit
`all_landscapes[[i]] <- NULL` on failure — against a preallocated (already-in-bounds) list that
assignment would *remove* the element and reintroduce the identical bug in a different guise, so
the failure branch now does nothing and simply leaves the preallocated `NULL` in place. `sapply`
also swapped for `vapply` on the same line. Regression test added
(`test-create-training-landscapes.R`): a deterministic all-fail case (`spot_radius` within its own
valid range but geometrically impossible at the given landscape size, so every attempt aborts
inside the generator) — with zero successes, every position is effectively a trailing failure,
pinning both the correct `"Generated 0/3 ... (3 failed)"` message and the empty return. Verified:
`devtools::test()` (2398 pass / 0 fail) and `dev/golden/check_landscapes.R` (byte-exact, all 11
patterns) — no change to any valid-input output.

### M8. Invalid pattern names are silently dropped in `create_landscapes()`  — [ChatGPT] [Fable] *(ChatGPT §D)*
*Fixed 2026-08-10.* `patterns <- intersect(patterns, valid_patterns)` silently ignored a mix of
valid and invalid names (only the all-invalid case errored) — a typo could quietly shrink the
requested pattern set and distort the class distribution instead of raising an error.
**Fix:** abort as soon as any unknown pattern name is present, naming the offending name(s) and
the valid options — matching `create_landscape()` (singular), which already aborted on an invalid
pattern. Chose abort over warn-and-continue for consistency with that sibling function, and
because a silently distorted training-set distribution is a worse failure mode than an upfront
error. Existing all-invalid test updated to the new message; new regression test added for the
mixed valid/invalid case (`test-create-training-landscapes.R`). Verified: `devtools::test()`
(2399 pass / 0 fail) and `dev/golden/check_landscapes.R` (byte-exact) — no change to any
valid-input output.

### M12. Generation failures are swallowed with no cause surfaced  — [Claude] *(§3.1)*
*Fixed 2026-08-10.* `try_create_landscape()` caught **every** error and returned `NULL`; the user
saw only the generic "Retry k/3 … Failed …" messages, so a genuinely broken parameter combo was
indistinguishable from bad luck — this is the mechanism that hid M7 for as long as it did.
**Fix:** the `tryCatch`'s `error` handler now reports `conditionMessage(e)` via
`cli::cli_alert_danger()` before returning `NULL`, e.g. *"Landscape 5 (pattern: clustered) failed:
Scatter zone too small for cluster size. …"* — printed unconditionally (no new `verbose` parameter;
the existing retry/failure messages in `create_landscapes()` were already unconditional, so this
matches that precedent rather than introducing a second reporting mode). Existing direct test of
`try_create_landscape()` extended to assert the cause is reported, not just that it returns `NULL`.
Verified: `devtools::test()` (2400 pass / 0 fail) and `dev/golden/check_landscapes.R`
(byte-exact) — no change to any valid-input output; only what gets printed on failure.

### M23. Sampled batch parameters are never validated, and could not safely be
*Fixed 2026-08-10.* `sample_landscape_params()` drew each landscape's parameters from
`batch_range`, and nothing checked the result against the same spec's `min`/`max` before it
reached the generator. Routing the draw through `pattern_*()` validation directly was not safe
where it would land: `try_create_landscape()` wraps generation in `tryCatch(error = \(e) NULL)`,
so a validation failure would become a retried-then-dropped landscape — a short training set,
which is a worse failure than no check at all.
**Fix:** new `validate_sampled_params()` (`R/landscape_parameter_validation.R`), reusing the same
`validate_logical_param()`/`validate_integer_param()`/`validate_numeric_param()` functions
`validate_params_list()` already applies to user-supplied values. Called in the retry loop right
after sampling but *before* `try_create_landscape()`, i.e. outside its `tryCatch` — so a violation
now aborts the whole `create_landscapes()` call instead of being silently retried away.

**Immediately found a real bug it was meant to guard against.** `bands`/`band_thickness`'s
`batch_range = function(width, height) c(0.02, 0.04) * height` gives `[0.4, 0.8]` at `height = 20`
— no whole number in that range at all — yet the parameter is declared `type = "integer"`.
`sample_landscape_params()`'s integer branch did `seq(from = range[1], to = range[2], by = 1)`,
which starts *exactly* at `range[1]` rather than rounding to it, so any range with a fractional
lower bound silently sampled a fractional value (e.g. `0.4`) that no generator ever checked either.
Affects the 5 integer parameters with a width/height-scaled `batch_range`
(`bands`/`band_thickness`, `bands`/`band_spacing`, `bands`/`amplitude`, `spots`/`spot_radius`,
`gaps`/`spot_radius`). **Checked against the sizes that matter:** at 100×100 (the paper's standard
size) and 50×50 (the robustness-test training size), every one of the 5 ranges already lands on
whole numbers, so this was never reachable in any published result — only this package's own
20×20 test fixtures (used for speed) hit it.
**Fix:** round the range inward (`ceiling`/`floor`) before building the candidate sequence,
falling back to `round(mean(range))` when that leaves no whole number at all. A no-op whenever the
range already starts and ends on whole numbers, which is every case that matters for published
results — confirmed by the unchanged golden references below.

Regression tests added for both parts (`test-create-training-landscapes.R`): a direct
`validate_sampled_params()` test with a manufactured out-of-bounds value, and a
`sample_landscape_params()` test covering both a range with no whole number at all and a
fractional-lower-bound range that does span whole numbers. Verified: `devtools::test()`
(2406 pass / 0 fail), `dev/golden/check_landscapes.R` (byte-exact, all 11 patterns) and
`dev/golden/check.R` (metrics within `1e-8`, pixel within `1e-5`) — **no result changes** at any
size the package actually generates landscapes at.

### L9. Default parameters drift between single generators and the batch wrapper  — [Claude] *(§2.5)*
*Fixed 2026-08-10 — decided: harmonize the generator defaults into the spec's batch range.*
7 parameters across 4 patterns had a signature default outside their own `batch_range` (at the
generators' own default width/height = 100): `fingers/sine_height_sd` (4, range `[5,25]`),
`bands/band_zone_prop` (0.2, range `[0.3,0.6]`), `bands/frequency` (2π/100, range `[0.1,0.3]`),
`spots/n_spots` (15, range `[5,10]`), `spots/spot_radius` (5, range `[10,20]`), and the same two
for `gaps`.

**Why this cannot change `create_landscapes()` output.** Confirmed by reading the merge logic
(`R/landscape_create.R`): for every parameter with a `batch_range`, the batch path *always*
supplies an explicit value — either the user's override or the spec's own `batch_range` — before
sampling. It never falls through to a generator's own formal default, whether or not the user's
`params_list` mentions that pattern. Only `create_landscape()` (singular) and the `pattern_*()`
constructors, called with a parameter omitted, ever consult the generator's default.

**Checked before touching anything:** no call anywhere in the analysis repo that produces a
published figure/table relies on these defaults — every real `pattern_spots()`/`pattern_gaps()`
call there sets both `n_spots` and `spot_radius` explicitly, and every `fingers`/`bands` landscape
there goes through the (unaffected) batch path. 8 low-stakes doc/vignette examples in this repo
do omit one of these parameters and now render slightly differently — checked by running each one
directly; all still execute without error.

**New defaults** — `sine_height_sd = 5`; `band_zone_prop = 0.3`; `frequency = 4*pi/100` (kept
tied to π rather than becoming an arbitrary decimal — this is "2 full waves across the default
width" instead of the old "1 full wave", the smallest multiple that lands in range);
`n_spots = 5`, `spot_radius = 10` for both `spots` and `gaps`.
**Chosen by visual inspection, not just picking the range midpoint:** the midpoint choice for
spots/gaps (`n_spots=8, spot_radius=15`) reliably produced heavily overlapping, merged blobs
across every seed tried — not a fluke, but also not a *wrong* depiction of the pattern class
(batch training data already samples `spot_radius` up to 20 and does include coalescing patches),
just a poor choice for an illustrative single-landscape default. The range's low end
(`n_spots=5, spot_radius=10`) stayed visually distinguishable as discrete spots/gaps across
multiple seeds and was chosen instead — which also matches the "sits at the low end of its range"
convention several *other* defaults in this spec already follow (`sine_height_mean`,
`sine_length_mean`, `band_spacing`, `noise_sd`).

**One non-obvious side effect, understood and expected:** the golden landscape harness's `single`
section generates all 11 patterns in one sequence sharing a single RNG stream. `spots`'/`gaps`'
placement draws `n_spots` values via `sample()`, so dropping their default from 15 to 5 changed how
many random draws are consumed immediately before `labyrinth` runs right after them in that
sequence — shifting `labyrinth`'s single-landscape matrix too, even though nothing about
`labyrinth` itself changed. Confirmed harmless: `labyrinth`'s own defaults/params are untouched,
and this coupling is an artifact of the harness generating all patterns from one shared seed, not
something a real caller generating `labyrinth` on its own would ever see. `dev/golden/reference_landscapes.rds`
re-captured after confirming (a) `batch_matrices`/`batch_params`/`batch_patterns` were 100%
byte-identical, and (b) every `single_matrices`/`single_params` diff was confined to exactly the
5 patterns expected to move (`fingers`, `bands`, `spots`, `gaps`, `labyrinth`).

**Two existing tests fixed as a side effect**, not a regression: `test-create-landscape.R` had two
tests using `width = height = 20` as an arbitrary small size, unrelated to what they actually test
(`pattern_label`/`name` field separation; rotation being ignored for non-rotatable patterns) — the
new `spot_radius = 10` default is exactly at the `spot_radius >= min(width,height)/2` boundary at
that size, so both needed bumping to `width = height = 50`, matching the convention already used
by sibling tests.

Verified: `devtools::test()` (2406 pass / 0 fail), the constructor-vs-generator defaults
consistency test (`test-pattern-params.R`) confirms the two copies stayed in sync,
`dev/golden/check_landscapes.R` clean against the re-captured reference, and
`dev/golden/check.R` (metrics within `1e-8`, pixel within `1e-5`) confirms the classification
harness — batch-path only — is completely unaffected.

### M21 + M18 + M19 + M20 + M22 (step 1). Per-pattern parameter constructors (`pattern_*()`)  — [new]
*Fixed 2026-08-06/07*, as Milestones 0–5 behind the existing golden harness. Full decision log kept
in `../spatPatClassifyR_paper/PATTERN_CONSTRUCTORS_PLAN.md` until its deletion (2026-08-10); the
dated summary that supersedes it is in `../spatPatClassifyR_paper/CHANGELOG.md`, 2026-08-06 and
2026-08-07. Five review items land together because they were one fix:

- **M21** (the design): one exported constructor per pattern — `pattern_spots()`, `pattern_bands()`,
  … — whose formals are that pattern's parameters, returning a plain list classed
  `"landscape_params"`. `pattern_<TAB>` now lists all 11 patterns; `?pattern_spots` is a real,
  inherited-`@param` help page; validation happens at construction time via the existing
  `validate_*_param()` functions, so the constructor and `params_list` cannot drift apart in what
  they accept. Reviewed by GPT-5.4 and Gemini before the rollout.
- **M18** (parameters undiscoverable): resolved by the constructors themselves, not by doc-only
  topics — the originally planned `?landscape_patterns` overview and `desc` spec field were dropped
  once the constructors made them redundant. The 11 generators are now `@noRd` (no dead-end pages);
  `_pkgdown.yml`'s reference index swapped to the constructor pages in the same commit.
- **M19** (undocumented behaviour): `create_landscape()`/`create_landscapes()` roxygen now states
  which 5 of 11 patterns honour `rotation`, documents `params_list`'s fixed-value-vs-range semantics,
  documents the partial-failure return shape, and lists `name` in `@return`. `custom_pattern` renamed
  to **`pattern_label`** in the same pass (it read as "a pattern to generate", not a relabeling knob).
- **M20** (vignette shape): `vignettes/landscape-generation.qmd` restructured around the 2-function
  API, including a one-figure-per-pattern visual tour.
- **M22 step 1** (`random_spots` silently stripped in batch generation): split into two scalars,
  `noise_veg_to_bare` / `noise_bare_to_veg`, added to the spec with `batch_range = NULL`
  (validation-only). Removes the package's only vector-valued parameter. **Changes no existing
  raster** — `random_spots` was never reachable through `create_landscapes()`.
- **M22 step 2** (2026-08-11): resolved by removing both parameters from the package rather than
  giving them a `batch_range`. Gone from the three ecotone generators, the spec table, the
  `pattern_*()` constructors, and the vignette; `validate_noise_prob()` deleted as its only callers
  were these. `pattern_sharp()` is now a single-parameter constructor. **Changes no raster** — both
  defaulted to 0 and the flip block was guarded by `if (noise > 0)`, so it consumed no RNG at the
  defaults; the golden landscape matrices are byte-identical and the classification harness passes
  without re-blessing. Only the stored `params` lists lose the two keys, so
  `reference_landscapes.rds` was recaptured.

  A trial of the alternative (`batch_range = c(0, 0.01)`) was measured first and rejected: for
  `clustered` it re-randomized the whole cluster layout rather than adding speckle, because
  `create_landscape_clustered()` builds its base through `create_landscape_sharp()` *before*
  sampling cluster centres, so switching noise off 0 shifts the stream. At noise = 1e-12, which
  flips essentially nothing, clustered already differed by 584 of 10000 cells.

As a consequence of Milestone 4, `create_landscape()` no longer takes `...` — the constructors are
now the *only* route for pattern parameters, a deliberate breaking change (`DESCRIPTION` → `0.3.0`).
The analysis repo's two call sites that pass pattern parameters were migrated in the same window,
which also surfaced and fixed a pre-existing, unrelated breakage (`tree_prop` → `veg_prop`, stale
since a much earlier rename, independent of this work).

**Verified 2026-08-10:** full suite (2396 pass / 0 fail), `dev/golden/check_landscapes.R` byte-exact
(all 11 patterns), `dev/golden/check.R` within tolerance (metrics `1e-8`, pixel `1e-5`), and a full
`devtools::check()` — 0 errors / 0 warnings, 6 NOTEs, none touching this work (sandbox `.claude` dir,
clock skew, `scratch/` not in `.Rbuildignore`, plus pre-existing NOTEs unrelated to landscape
generation). **No result changes.**

### L24 + the `plot_classified_landscapes()` batch  — [Fable] [new]
*Fixed 2026-08-05*, as six small independently-verified commits. **L24** was the entry point: with a
model at 100% accuracy the `only_misclassified = TRUE` branch aborted with *"No misclassified
landscapes found"*, breaking a clean `source()` of all six analysis scripts, which pass that
argument. It now reports the outcome with a `cli` message and returns an empty placeholder plot —
`invisible(NULL)` was rejected because every one of those scripts follows the call with
`ggsave(plot = fig)`, so it would only have moved the crash one line down (`3774463`).

Working through it surfaced four further defects in the same function, none of which came from the
three original passes:
- **Unlabeled landscapes counted as misclassified.** The filter dropped `actual_class = NA` but kept
  the equivalent `"unclassified"` sentinel, so landscapes with no ground truth were plotted as
  errors. `apply_*()` (`nn_keras.R:860,869,895`) already treats both forms identically when choosing
  rows to score; this was the one place that missed the string form. The no-prediction title was
  also renamed `"Unclassified"` → `"No prediction"`, since the same word in `actual_class` means the
  opposite thing — an unknown *true* class (`cb965ac`).
- **`subset_index` always errored.** Documented in `@param ...` as passable to `plot_landscapes()`,
  but that function subsets the landscapes without subsetting the titles generated here, so every
  subset failed its length check. Now a real formal argument applied to the classification rows
  after the `only_misclassified` filter. Hand-subsetting `classification` was no workaround either —
  it trips the length-mismatch warning by design (`73d8feb`).
- **Titles and validation.** `only_misclassified` unvalidated while `score_note` beside it was;
  `round(score, 2)` printing `1` next to `0.35` on adjacent panels; the score-note caption inheriting
  ggplot2's right-aligned default. Also closes the `R/plot_classification.R` half of **L17** — the
  doubled `sapply(landscapes, is_landscape)` is now one `vapply()` (`c93eac9`).

The two `REVISIONS.md` "Plotting" items were done in the same batch: CVD-safe Okabe-Ito title
colours with bold as the redundant cue (`b129f00`), and left-aligned panel titles (`7708508`) —
the latter traced to `e37aa45`, the **H1** fix below, whose `%+replace%` discarded the `hjust = 0`
both ggplot2 base themes set on `plot.title`. Full suite green after each commit (1993 pass / 0
fail at the end). **Appearance-changing:** regenerate every landscape figure from `7708508` onward.

### M13 + M9 + M7. Parameter definitions duplicated in three places, and the two drifts it caused  — [Claude] [ChatGPT] [Fable] *(§3.2 / ChatGPT §E / ChatGPT §A)*
*Fixed 2026-08-04*, as one consolidation with two follow-on fixes. Per-pattern parameter knowledge
lived in three independently-maintained places — each `create_landscape_*()` signature,
`create_landscapes()`'s `default_params_list`, and `get_valid_param_specs()` — and they had
already drifted apart in two user-visible ways.
- **M13:** introduced `landscape_param_specs()` (`R/landscape_parameter_validation.R:137`) as the
  single canonical table: `type`, `min`/`max`, and `batch_range` (a literal vector, a
  `function(width, height)` for size-scaled ranges, or `NULL` for validation-only parameters).
  `get_valid_param_specs()` (validation) and `build_default_params_list()` (batch defaults) now
  both derive from it, as does the integer-vs-continuous sampling decision, which was previously a
  hardcoded name list in `create_landscapes()`. Commits `0021e85`, `1640346`.
- **M9:** `radius_noise_fraction` added to the spots/gaps spec — it had been silently stripped
  from any `params_list`, so it was stuck at the generator default `0` in *every* batch-generated
  landscape ever produced. Given `batch_range = NULL` so existing results are unaffected; whether
  it should be randomized is now tracked as **L25**. Commit `fdfa3ce`.
- **M7:** the phantom `invert_landscape` entry removed from the `gaps` spec — validation accepted
  it, then the generator (which hardcodes `TRUE`; that *is* the spots/gaps distinction) failed
  with "unused argument", swallowed by `try_create_landscape()`. `gaps` stays non-invertible.
  Commit `d7330f0`.

Done as small individually-verified steps behind a new exact-match golden harness for landscape
generation (`dev/golden/run_golden_landscapes.R`, commits `6b376eb`/`09dd47b`), added *first* as
the safety net. Verified: 1938 tests pass / 0 fail, `R CMD check` 0 errors / 0 warnings (same 4
pre-existing NOTEs), landscape golden check byte-exact across all 11 patterns, classification
golden check within tolerance, and one ecotone + one self-organized analysis-repo use case re-run
against the installed local package. **No result changes.** New tests in
`tests/testthat/test-landscape-parameter-specs.R`. The same session also reduced the public
creation API from 13 exported functions to 2 (`create_landscape`, `create_landscapes`; commits
`17c2e62`, `49a0ae5`) — which is what **M18/M19/M20** now follow up on, since the documentation
did not follow the API.

### M10. `apply_metric_model()` has no `verbose`; `apply_pixel_model()` does  — [Claude] *(§2.1)*
*Fixed (verified present 2026-08-05).* `apply_metric_model()` (`R/nn_metrics.R:518-523`) now takes
`verbose = TRUE` as a formal argument, validates it, and threads it into
`evaluate_cv_performance()` instead of hardcoding `TRUE`, matching `apply_pixel_model()`. Logged in
`../spatPatClassifyR_paper/REVISIONS.md` under "Kleine Bugs".

### L3. [Fable] Metrics classifier `confidence` is an uncalibrated post-hoc softmax  — [Fable] *(F6)*
*Fixed 2026-08-03.* Raw `neuralnet` outputs are now projected onto the probability simplex and the
column renamed `confidence` → `score`, making the "this is a relative score, not a calibrated
probability" point explicit rather than implied. Full write-up, measured before/after numbers and
the rejected alternatives are in `../spatPatClassifyR_paper/CLASS_SCORES.md`; commits `d0d8f13`,
`5603825`, `b329c2f`, `c80ac14`. Supplement §S1.5.1, §S1.6 and the Figure S1/S2 captions updated.
(The second half of the original finding — that SSE-to-one-hot is a weaker objective than
cross-entropy — was considered and deliberately not changed; the classifier is argmax-based and
accuracy is unaffected.)

### L23. Tests missing for several user-facing mismatches  — [ChatGPT] [Fable] *(ChatGPT §F)*
*Complete (verified 2026-08-05).* All four named gaps now have coverage: `theme_landscape()`
composition (H1) in `test-plot_themes.R`; unknown-class / missing `actual_class` plotting (H3) in
`test-plot_classification.R:189`; `gaps + invert_landscape` (M7) in
`test-landscape-parameter-specs.R:150`; `frequency` sampling for bands (M2) in
`test-create-training-landscapes.R`. The remaining M17 clause (M3, trailing-failure counts) was
closed 2026-08-10 — see **M17** and **M3** under **Completed**.

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
