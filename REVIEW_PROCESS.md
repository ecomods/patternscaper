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
> Triaged and partially worked since. **Last re-verified against the source 2026-08-05** — every
> item below was checked against the current code, not just carried forward. Items marked
> **[new]** were added at or after that re-verification — each carries its own date — and did not
> come from the three original passes.

---

## 🔴 High — likely wrong behaviour or a user-facing error; fix before release

*All resolved — see **Completed** at the bottom (H1, H2, H3).*

---

## 🟠 Medium — real inconsistency, latent bug, methodological issue, or maintainability risk

### M3. `create_landscapes()` failure bookkeeping is fragile (trailing failures misreported as full success)  — [Claude] [Fable] *(§1.4 / F5)*
*Confirmed still open 2026-08-05; line refs updated after the M13 refactor.*
`R/landscape_create.R:388-410`. On failure the code does `all_landscapes[[i]] <- NULL`, which
**removes** the element rather than reserving a slot. For a **trailing** failure the list
simply stays short, so `n_failed <- sum(sapply(..., is.null))` (`:398`) counts only interior
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

### M8. Invalid pattern names are silently dropped in `create_landscapes()`  — [ChatGPT] [Fable] *(ChatGPT §D)*
`R/landscape_create.R:248` uses `patterns <- intersect(patterns, valid_patterns)`. A mix of
valid and invalid names silently ignores the invalid ones (only the all-invalid case errors).
Fable confirmed; still open 2026-08-05.
- **Effect:** typos can quietly change the requested class set and distort the pattern
  distribution.
- **Fix:** warn or abort on unknown entries instead of silently dropping them.

### M11. Inconsistent return shape when `return_performance = TRUE`  — [Claude] [ChatGPT] *(§2.2)*
`apply_pixel_model()` always returns `list(predictions, performance)` (performance may be
`NULL`); `apply_metric_model()` returns a **bare tibble** in some branches (unknown classes,
`R/nn_metrics.R:550`) and a **list** in others (`:576-579`). Downstream
(`plot_classified_landscapes`, the analysis repo) can't rely on a stable shape.
- **Fix:** pick one contract and apply it to both. **[ChatGPT] nuance:** the docs already say
  metrics returns predictions-only when classes are unknown, so treat this as an API-design
  inconsistency rather than a pure correctness bug.

### M12. Generation failures are swallowed with no cause surfaced  — [Claude] *(§3.1)*
`R/landscape_create.R:480-503` (error handler at `:499-501`). `try_create_landscape()` catches
**every** error and returns `NULL`; the user sees only generic "Retry k/3 … Failed …". A genuinely
broken parameter combo is indistinguishable from bad luck. Still open 2026-08-05 — note this is
the mechanism that hid M7 for as long as it did, which is the argument for fixing it.
- **Fix:** capture and (at least in verbose mode) report `conditionMessage(e)`.

### M18. [new] Landscape parameters are undiscoverable through the public API  — *(added 2026-08-05)*
Fallout from the 2026-08-04 unexport (see the M13/M9/M7 entries under **Completed**). The 11
`create_landscape_*()` generators are now `@keywords internal`, but they are still where every
per-pattern parameter is documented — and both public functions point users at them:
- `create_landscape()` (`R/landscape_create.R:15-16`): *"See the documentation of the individual
  functions for details on required and optional parameters."* Those pages are now internal and
  off the pkgdown reference index.
- `create_landscapes()` (`R/landscape_create.R:150-152`): `params_list` says the names and default
  ranges *"can be found in the documentation of `create_landscape`"* — where they are not.

**Effect:** a user has no documented route to learn that `spots` takes `n_spots` /
`spot_radius` / `spot_radius_sd` / `radius_noise_fraction` / `regular_spots`, what their bounds
are, or what ranges the batch generator samples by default. The API got smaller (good) but the
documentation did not follow it.
**Verified 2026-08-05** (against the installed package): `?create_landscape_bare` *does* resolve —
`@keywords internal` affects indexing, not the help page — but 0 of the 11 topics appear in the
installed `INDEX`, so `help(package = "spatPatClassifyR")` does not list them. Reachable by exact
name, invisible when browsing. `_pkgdown.yml` already lists all 11 explicitly, so the *website*
side is fine; the console side is not.

**Approach — superseded by M21 (2026-08-06).** The `pattern_*()` constructors *are* the per-pattern
documentation, so the doc-only route is dropped: no `desc` field on the spec, no generated
`?landscape_patterns` overview topic. What survives from this entry:
1. **`@noRd` the 11 generators** once their content has moved, removing the dead-end pages. ⚠️
   `_pkgdown.yml` lists all 11 topics explicitly and pkgdown *errors* on an unresolvable
   `contents:` entry — that section must be updated in the same commit.

**Why not keep the docs on the generator pages:** the `\usage` section would show a signature the
user cannot call, and `Usage` is the affordance users copy from; a "do not call directly" note does
not fix that. Precedent for doc-only topics (verified locally): `?mgcv::smooth.terms` and
`?mgcv::gam.models` are topics with no function of that name; `parsnip` uses `?details_*` per
engine.

**Backstop against drift:** add a test comparing the spec's parameter names per pattern against
the corresponding `create_landscape_*()` formals (minus `width`/`height`), so a mismatch fails the
suite instead of waiting to be noticed.

### M19. [new] `create_landscape()`/`create_landscapes()` docs don't describe what actually happens  — *(added 2026-08-05)*
Beyond the missing parameter table (M18), the two public help pages leave the batch behaviour
undocumented:
- **Rotation applies to only 5 of 11 patterns** and is silently dropped for the rest — see L10.
- **`custom_pattern`** (`R/landscape_create.R:13-14`) is one cryptic line ("Optional pattern for
  the landscape") with no explanation of why you would relabel a landscape and no example.
- **How `params_list` values are interpreted** — a length-2 vector is a range sampled per
  landscape, a length-1 value is fixed, logicals are sampled from the supplied set — is only
  visible by reading `sample_landscape_params()`.
- **What `create_landscapes()` returns on partial failure** is undocumented (and currently
  mis-reported — see M3).
- **The `@return` of `create_landscape()`** describes `data`/`pattern`/`params` but not `name`,
  which the constructor does set.

### M20. [new] Vignette is still organised around the now-internal generators  — *(added 2026-08-05)*
`vignettes/landscape-generation.qmd` — the "Creating Single Landscapes" half (§"Spot Patterns",
§"Clustered Patterns", §"Labyrinth Patterns") is structured per generator function, which no
longer matches the 2-function public API. It does *not* call the internal functions directly
(checked — it goes through `create_landscape()`), so it is not broken, just mis-shaped.
- **Fix:** restructure around `create_landscape()` / `create_landscapes()` once M18 lands, and
  link the parameter reference from it.
- **Partly on hold (M21).** The *visual tour* half — one figure per pattern showing what it looks
  like — is safe to write now and is arguably the vignette's main job (it answers "which pattern do
  I want?" far better than a help page can). The *parameter-passing* sections are not: if M21 lands
  they would need rewriting from `list(n_spots = 15)` to `spots_params(n_spots = 15)`.

### M21. [new] Per-pattern parameter constructors (`pattern_spots()` …)  — *(added 2026-08-05)*
**DECIDED 2026-08-05: go ahead.** Step-by-step implementation plan, milestones and verification
schedule live in `../spatPatClassifyR_paper/PATTERN_CONSTRUCTORS_PLAN.md` (temporary working
document — delete when done). This supersedes M18 steps 3–4: the `pattern_*` help pages *are* the
per-pattern documentation, so no doc-only topics are needed. Naming settled as `pattern_*` (not
`*_params`) so `pattern_<TAB>` lists all 11.

Because `create_landscape()` dispatches through `...`, pattern parameters are invisible to
autocomplete: typing `create_landscape("spots", ` will never suggest `n_spots`. Completion is
driven by `formals()`, and `...` has nothing to offer. No documentation fixes this — only an API
change does.

**The idiom:** export one small parameter-constructor per pattern whose formals *are* that
pattern's parameters, returning a validated plain list:

    create_landscape("spots", params = spots_params(n_spots = 15, spot_radius = 10))
    create_landscapes(n = 50, params_list = list(spots = spots_params(n_spots = c(5, 10))))

Established R pattern for "one entry point, many type-specific parameter sets":
`stats::glm(family = binomial(...))` and its `control = glm.control(...)`, `lme4::lmerControl()`,
`ggplot2::element_text()`, `keras3::optimizer_adam()` (already a dependency).

**What it would solve beyond autocomplete:**
- The typo hazard disappears — `spots_params(n_spot = 5)` errors at the call site instead of
  silently partial-matching (single path) or being warned-and-ignored (batch path).
- **It resolves the M18 documentation problem outright.** `?spots_params` is a real exported
  function with an honest `\usage`, runnable examples, and an entry in `help(package=)` — no
  doc-only topics, no `\usage` lie, no dead-end pages on non-callable functions.
- Validation moves to construction time, with the pattern known.

**Costs:** public API goes 2 → 13 exports again, partially reversing the 2026-08-04 reduction
(counter-argument: these are *parameter constructors*, not 11 ways to generate a landscape — the
"one obvious way to generate" property is preserved). It is real code, not just docs. And the
value depends on how much autocomplete matters for a companion package whose users mostly copy
from vignettes.

**Cheapness:** it can be **purely additive** — `spots_params()` returns a plain list, so
`list(n_spots = 15)` keeps working unchanged. No deprecation, no result change. Verified
2026-08-05: the analysis repo has **zero** `params_list` call sites, so the blast radius is nil.

**Consequence for M18/M19/M20:** no doc-only per-pattern topics, and no `?landscape_patterns`
overview topic — the `pattern_*` help pages replace both.

### M22. [new] `random_spots` is silently stripped in batch generation — M9 all over again  — *(found 2026-08-05)*
`random_spots` is a working formal of `create_landscape_sharp()`, `create_landscape_fingers()` and
`create_landscape_clustered()`, and has its own validator (`validate_random_spots()`,
`R/landscape_parameter_validation.R:102`) — but it is **not in `landscape_param_specs()`**, so
`validate_params_list()` treats it as unknown and drops it. Verified 2026-08-05:

    create_landscape("sharp", random_spots = c(0.3, 0.3))   # works, changes the landscape
    create_landscapes(n = 2, patterns = "sharp",
                      params_list = list(sharp = list(random_spots = c(0.3, 0.3))))
    #> ! Unknown parameter "random_spots" for pattern "sharp" - will be ignored
    #> params actually used: 0 0

**Effect:** every batch-generated `sharp` / `fingers` / `clustered` landscape has
`random_spots = c(0, 0)` — no cell-flipping noise — with no way to change it through
`create_landscapes()`. These are the paper's **ecotone** patterns, i.e. the primary use case.
Structurally identical to M9 (`radius_noise_fraction`), which the M13 consolidation fixed for
spots/gaps; this one was missed because nothing compared the spec against the generator formals.
Found by running M18's proposed consistency test while writing the implementation plan — which is
the argument for that test existing.

**Fix — decided 2026-08-06: split the parameter, in two deliberately separate steps.** A length-2
value cannot be added to the spec as-is: the batch path reads length 2 as a *range* to sample from,
so it would be collapsed to a scalar, rejected inside the generator, and swallowed by
`try_create_landscape()` — a silently dropped landscape, worse than today's warning.
  1. Replace `random_spots` with two scalars, `noise_veg_to_bare` and `noise_bare_to_veg`, and add
     all six entries to the spec with `batch_range = NULL` (validation-only) → settable through
     both entry points, **changes no existing raster**. Removes the package's only vector-valued
     parameter, so no `arity` concept is needed and the shared validator/sampler are untouched.
     Milestone 0.2 of `../spatPatClassifyR_paper/PATTERN_CONSTRUCTORS_PLAN.md`, which carries the
     full usage inventory showing the parameter has never influenced a published number.
  2. *Later, separately:* decide whether the two deserve a default `batch_range`.
     **Results-changing** — same open decision as L25, and on the paper's main patterns. See
     "Open decisions".

### M23. [new] Sampled batch parameters are never validated, and could not safely be  — *(added 2026-08-07)*
`sample_landscape_params()` draws each landscape's parameters from `batch_range`, and nothing
checks the result against the same spec's `min`/`max` before it reaches the generator. The obvious
fix — routing the draw through the `pattern_*()` validation — is **not** safe where it would land:
`try_create_landscape()` wraps generation in `tryCatch(error = \(e) NULL)`, so a validation failure
becomes a retried-then-dropped landscape and `create_landscapes(n = 100)` quietly returns 97 with a
warning. A short training set changes results; that is a worse failure than no check at all. Same
`tryCatch` as M12, different fix: M12 wants the cause *reported*, this wants the error class *not
to arrive there in the first place*.

**Not currently reachable.** Measured 2026-08-07 while implementing Milestone 4.1: no `batch_range`
sits outside its own `min`/`max` at 50×50, 100×100, 200×200, 500×200 or 30×300, and 3,300 draws
(300 per pattern) produced zero rejections. The invariant *batch_range ⊆ [min, max]* holds today —
but nothing enforces it, so widening a range later would surface as short batches.

**Why it is open rather than fixed:** Milestone 4.1 rewired the batch path onto `params =` and
deliberately used `new_landscape_params_unchecked()` (`R/pattern_params.R`) to keep behaviour
provably identical, since that milestone claims zero results impact. Adding validation is new
behaviour and belongs on its own.
- **Fix:** validate the sampled draw *outside* the `tryCatch`, so a spec bug is a loud error rather
  than a short batch. Pairs naturally with M12 and with M0.1's spec-vs-formals consistency test,
  which guards the adjacent drift class.
- **Cheaper alternative:** a test asserting `batch_range ⊆ [min, max]` for every spec entry across
  several landscape sizes — enforces the invariant without touching the generation path.

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
*Partially done.* (H1) `theme_landscape()` and (M2) `frequency` variation both have tests
(`test-plot_themes.R`, `test-create-training-landscapes.R`). **Remaining:** (M3)
`create_landscapes()` reports correct success/fail counts on a **trailing** failure.

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

### L9. Default parameters drift between single generators and the batch wrapper  — [Claude] *(§2.5)*
*Mostly resolved 2026-08-04 by M13.* Two of the three sources are now derived from
`landscape_param_specs()`. **Remaining — the third axis:** each generator's own *signature
defaults* are still written independently of the spec. E.g. `create_landscape_gaps()` has
`n_spots = 15` (`R/landscape_create_gaps.R:43`) while the spec's `batch_range` is `c(5, 10)`, so
`create_landscape("gaps")` and `create_landscapes(patterns = "gaps")` produce
differently-distributed landscapes with no note anywhere saying so.
- **Fix (decide first):** either derive the signature defaults from the spec too, or accept the
  divergence deliberately and document it under M18/M19 — a single-landscape default and a batch
  sampling range arguably *should* differ, but right now the difference is accidental.

### L10. Rotation silently ignored for most patterns  — [Claude] *(§3.3)*
Only `c("sharp","diffuse","fingers","clustered","bands")` (`R/landscape_create.R:328-334`) honour
`rotation`; for the others it's silently dropped. Document in `create_landscapes()` (and ideally
warn if a non-zero rotation is set for a pattern that ignores it). *Note 2026-08-05:* the doc
half of this is now folded into M19; the warning half stays here.

### L25. [new] `radius_noise_fraction` has no default batch range — open decision  — *(added 2026-08-05)*
M9's fix made `radius_noise_fraction` a valid, settable `params_list` parameter, but deliberately
gave it `batch_range = NULL` (`R/landscape_parameter_validation.R:319-324`) so published results
were unaffected. **Consequence:** every batch-generated spots/gaps landscape still uses the
generator default `0` — perfectly sharp circular edges — in all training and test sets.
- **Decision needed:** should it get a `batch_range` so edge noise is randomized like the other
  spots/gaps parameters? This is a **results-changing** decision — it would alter
  self-organized-pattern accuracy and require re-running those use cases. Tracked with the
  analysis-side context in `../spatPatClassifyR_paper/REVISIONS.md` (`## Code`).

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

### L19. Inconsistent source-file naming  — [Claude] *(§5.5)*
`create_landscape_bare.R` / `create_landscape_dense.R` vs the other nine `landscape_create_*.R`,
with dispatcher `landscape_create.R`. Pick one convention (e.g. `landscape_create_*.R`, now the
majority) and rename for discoverability. Confirmed still open 2026-08-05. Pure file rename — no
behaviour change, no `man/` change.

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

**Group A — cannot change any result** (docs, messages, tests, file names). *In progress.*
**Constraint (2026-08-05): do only work that survives the M21 decision either way.** M21
(per-pattern parameter constructors) would replace per-pattern doc topics with `?spots_params`
pages, so anything built per-pattern now is at risk of being thrown away.

*Safe regardless of M21 — do these:*
1. **M19** — document rotation applicability, `custom_pattern`, `params_list` semantics, `@return`.
2. **L26** — one-line `_pkgdown.yml` fix so `build_reference()` stops erroring.
3. **L19** — file renames; **L17** — `sapply()` → `vapply()`; **L21** — README badges.
4. **M20**, visual-tour half only — one figure per pattern in the vignette.

*On hold until M21 is decided — do NOT start:*
- 11 per-pattern doc-only topics (M18 step 3).
- Rewriting the generators' `@examples` to `create_landscape("bands", ...)` — under either
  outcome those pages get `@noRd`'d, so the examples disappear. Skip entirely.
- The parameter-passing sections of the vignette (M20).

**Group B — changes only error/warning paths, not successful runs.** Existing golden checks
should stay byte-identical; only failure behaviour moves:
6. **M3 / M8 / M12 / M23** — the `create_landscapes()` failure path (miscounted trailing failures,
   silently dropped invalid pattern names, swallowed error causes, unvalidated sampled parameters),
   plus the M17 test. M12 and M23 are the same `tryCatch` from opposite ends — report the cause vs.
   keep validation errors from reaching it — so they are best taken together.
7. ~~**L24** — `plot_classified_landscapes(only_misclassified = TRUE)` at 100% accuracy.~~ *Done
   2026-08-05, together with the rest of the `plot_classified_landscapes()` batch — see
   **Completed**.*
8. **L7** — single-landscape handling parity between the two `apply_*`.

**Open decisions (not tasks — settle these before the work they gate):**
- **L25** — `radius_noise_fraction` batch randomization. Gates a self-organized re-run.
- **M22 step 2** — batch randomization of `noise_veg_to_bare` / `noise_bare_to_veg` (post-split).
  Same question, on the *ecotone* patterns. Worth deciding together with L25: they are the same
  decision about whether batch training sets should vary edge/cell noise at all.
- **L9** — generator signature defaults vs. batch ranges.
- ~~**M21**~~ — decided 2026-08-05, go ahead; see `PATTERN_CONSTRUCTORS_PLAN.md`.

**Group C — will or may change results; needs the analysis re-run and a manuscript check:**
9. **L25** — `radius_noise_fraction` batch randomization *(decision first, then re-run)*.
10. **M11 / L22** — unify the `apply_*` return contract (touches the analysis repo's call sites).
11. **M5** — pixel-model input encoding (ordinal integers for 3+ classes). *(M6 was here too; done
    2026-08-05 by removing the `metrics` parameter, and it changed no results.)*
12. **L5** — `fisher_score` single-sample guard (changes metric ranking when it fires).
13. **L9** — generator signature defaults vs. batch ranges *(decision first)*.

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
`test-create-training-landscapes.R`. The remaining M17 clause (M3, trailing-failure counts) stays
open under **M17**.

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
