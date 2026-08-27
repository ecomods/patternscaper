# Golden regression harness -- landscape generation only.
#
# Unlike run_golden.R (which exercises 3 of 11 patterns through the full
# classification pipeline), this exercises ALL 11 patterns directly, through
# both create_landscape() and create_landscapes(), and captures the raw
# generated output (matrices + params) rather than downstream classification
# results. Landscape generation is pure deterministic R (RNG draws + array
# manipulation, no BLAS/keras noise), so this comparison can be exact -- see
# check_landscapes.R.
#
# Used by:
#   capture_landscapes.R -- freeze this as the reference
#   check_landscapes.R   -- re-run and compare current code against the reference
#
# Run from the PACKAGE ROOT. Uses the LOCAL package source via load_all(), so it
# always tests the code you are currently editing.

run_golden_landscapes <- function() {
  pkgload::load_all(quiet = TRUE)

  all_patterns <- c(
    "random",
    "bare",
    "dense",
    "sharp",
    "diffuse",
    "fingers",
    "clustered",
    "bands",
    "spots",
    "gaps",
    "labyrinth"
  )

  # Package default size (100x100) -- several patterns' default/batch
  # parameter ranges (e.g. clustered's cluster_radius, cluster_zone) are
  # calibrated in absolute pixels for this size and fail geometry checks on a
  # much smaller canvas. Generation itself is cheap even at this size (no
  # model fitting involved), so there's no speed reason to shrink it.
  width <- 100
  height <- 100

  # Batch path -- exercises create_landscapes()'s sampling/merge logic for
  # every pattern (3 landscapes per pattern) --------------------------------
  set.seed(123)
  batch <- create_landscapes(
    n = 3 * length(all_patterns),
    patterns = all_patterns,
    width = width,
    height = height
  )

  # Single path -- exercises create_landscape() directly, generator defaults,
  # for every pattern ---------------------------------------------------------
  # Seeded independently of the batch above: without this, a change to what the
  # batch samples shifts the stream position the single path starts from, and
  # every stochastic single landscape drifts for a reason unrelated to
  # create_landscape() itself.
  set.seed(456)
  single <- stats::setNames(
    lapply(all_patterns, \(p) create_landscape(p, width = width, height = height)),
    all_patterns
  )

  list(
    batch_matrices = lapply(batch, \(l) as.matrix(l$data)),
    batch_params = lapply(batch, \(l) l$params),
    batch_patterns = lapply(batch, \(l) l$pattern),
    single_matrices = lapply(single, \(l) as.matrix(l$data)),
    single_params = lapply(single, \(l) l$params)
  )
}
