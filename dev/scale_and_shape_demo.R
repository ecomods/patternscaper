# Title: Scale and shape behaviour of both classification workflows
# Date: 2026-07-23
# Author: Selina Baldauf
# Purpose: Exercise every extent / resolution / shape mismatch between training
#   and application data, so the current (partly silent) behaviour is visible and
#   can be re-checked after the guards are implemented.

# Run top to bottom. Each scenario prints the accuracy both workflows achieve, or
# the error they raise. Nothing here is a formal test - it is a manual harness.
#
# Expected behaviour AFTER the planned guards (see
# ../spatPatClassifyR_paper/SCALE_AND_SHAPE.md):
#
#   1 matched                  both workflows high accuracy, silent
#   2 larger, same aspect      pixel: works; metrics: warn about extent mismatch
#   3 smaller, same aspect     pixel: works; metrics: warn about extent mismatch
#   4 different aspect ratio   pixel: WARN about aspect-ratio distortion
#   5 finer grain, georef kept both workflows work (metrics unchanged in map units)
#   6 finer grain, georef lost metrics: warn about cell-size mismatch
#   7 irregular shape (NA)     metrics: works; pixel: ABORT with a clear message
#   8 mixed training sizes     pixel: ABORT with a clear cli message, not abind's

pkgload::load_all(quiet = TRUE)
library(dplyr)

set_random_seed(20260723)
patterns <- c("sharp", "diffuse", "bands", "random")
metric_pool <- c("ai", "contag", "cohesion", "lpi", "division", "ed", "np", "area_mn")

train_size <- 40

# Training data ----------------------------------------------------------------

train <- create_landscapes(
  n = 120,
  patterns = patterns,
  width = train_size,
  height = train_size
)

train_metrics <- calculate_metrics(train, metrics = metric_pool, level = "landscape")
selected <- evaluate_metrics(train_metrics, metrics_number = 5, verbose = FALSE)

metrics_model <- train_metric_model(
  train_metrics,
  metrics_selected = selected,
  cv_method = "none",
  stepmax = 1e6,
  verbose = FALSE
)

pixel_model <- train_pixel_model(
  train,
  cv_method = "none",
  epochs = 10,
  verbose = FALSE
)

# Test data for each scenario --------------------------------------------------

make_test <- function(width, height) {
  create_landscapes(n = 40, patterns = patterns, width = width, height = height)
}

# Pure resolution change: same extent, twice as many cells in each direction.
# Georeferencing is kept, so a cell is half as wide in map units.
refine_keep_georef <- function(l) {
  template <- terra::rast(
    nrows = 2 * terra::nrow(l$data),
    ncols = 2 * terra::ncol(l$data),
    extent = terra::ext(l$data),
    crs = terra::crs(l$data)
  )
  l$data <- terra::resample(l$data, template, method = "near")
  l
}

# Same pixels, but pushed back through a plain matrix so the cell size is reset
# to 1 - this is what happens when landscapes come from matrices, not rasters.
drop_georef <- function(l) {
  landscape(
    terra::as.matrix(l$data, wide = TRUE),
    pattern = l$pattern,
    name = l$name
  )
}

mask_circle <- function(l) {
  xy <- terra::xyFromCell(l$data, seq_len(terra::ncell(l$data)))
  centre_x <- terra::ncol(l$data) / 2
  centre_y <- terra::nrow(l$data) / 2
  radius <- 0.45 * min(terra::ncol(l$data), terra::nrow(l$data))
  l$data[(xy[, 1] - centre_x)^2 + (xy[, 2] - centre_y)^2 > radius^2] <- NA
  l
}

test_matched <- make_test(train_size, train_size)

scenarios <- list(
  "1 matched"                  = test_matched,
  "2 larger, same aspect"      = make_test(2 * train_size, 2 * train_size),
  "3 smaller, same aspect"     = make_test(train_size / 2, train_size / 2),
  "4 different aspect ratio"   = make_test(2 * train_size, train_size),
  "5 finer grain, georef kept" = purrr::map(test_matched, refine_keep_georef),
  "6 finer grain, georef lost" = purrr::map(test_matched, \(l) drop_georef(refine_keep_georef(l))),
  "7 irregular shape (NA)"     = purrr::map(test_matched, mask_circle)
)

# Run all scenarios ------------------------------------------------------------

accuracy_or_error <- function(expr) {
  result <- try(suppressWarnings(expr), silent = TRUE)
  if (inherits(result, "try-error")) {
    return(paste("ERROR:", trimws(sub("^Error[^:]*:", "", result[1]))))
  }
  if (is.null(result$performance)) return("no performance returned")
  as.character(round(result$performance$accuracy, 3))
}

report <- purrr::imap_dfr(scenarios, \(landscapes, label) {
  tibble::tibble(
    scenario = label,
    dims = paste(terra::nrow(landscapes[[1]]$data), "x", terra::ncol(landscapes[[1]]$data)),
    cell_size = terra::res(landscapes[[1]]$data)[1],
    n_na = sum(is.na(terra::values(landscapes[[1]]$data))),
    metrics = accuracy_or_error(
      apply_metric_model(landscapes, metrics_model, return_performance = TRUE)
    ),
    pixels = accuracy_or_error(
      apply_pixel_model(landscapes, pixel_model, return_performance = TRUE, verbose = FALSE)
    )
  )
})

cat("\n=== accuracy by scenario (chance =", round(1 / length(patterns), 2), ") ===\n")
print(report, n = Inf)

# Scenario 8: mixed sizes inside the training set ------------------------------

mixed_training <- c(
  create_landscapes(n = 4, patterns = patterns, width = 40, height = 40),
  create_landscapes(n = 4, patterns = patterns, width = 60, height = 60)
)

cat("\n=== 8 mixed training sizes ===\n")
mixed_result <- try(
  train_pixel_model(mixed_training, cv_method = "none", epochs = 1, verbose = FALSE),
  silent = TRUE
)
cat(if (inherits(mixed_result, "try-error")) mixed_result[1] else "trained without complaint\n")

# Does an NA landscape reach the CNN silently? ---------------------------------

masked <- mask_circle(test_matched[[1]])
masked_array <- terra::as.array(masked$data)
raw_prediction <- predict(pixel_model$model, abind::abind(list(masked_array), along = 0), verbose = 0)

cat("\n=== 7b NA handling detail ===\n")
cat("NA cells passed to the CNN:", sum(is.na(masked_array)), "\n")
cat("raw output contains NaN:", any(is.nan(raw_prediction)), "\n")
cat("raw output:", round(raw_prediction, 4), "\n")
cat("-> finite output here means the masked cells were silently absorbed\n")
