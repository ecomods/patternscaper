# Tests for create_landscapes() --------------------------------------

# Validation tests ------------------------------------------------------------

test_that("create_landscapes validates inputs", {
  # Invalid n - not positive
  expect_error(
    create_landscapes(n = 0),
    "'n' must be a positive integer"
  )

  expect_error(
    create_landscapes(n = -5),
    "'n' must be a positive integer"
  )

  # All-unknown patterns
  expect_error(
    create_landscapes(n = 10, patterns = c("invalid1", "invalid2")),
    "Invalid pattern\\(s\\): invalid1, invalid2"
  )
})

test_that("create_landscapes rejects a mix of valid and invalid pattern names (M8)", {
  # A typo mixed in with valid patterns must abort, not silently shrink the
  # requested pattern set to the valid subset.
  expect_error(
    create_landscapes(n = 10, patterns = c("random", "sharpp", "spots")),
    "Invalid pattern\\(s\\): sharpp"
  )
})

# Functionality tests ---------------------------------------------------------

test_that("create_landscapes returns correct number of landscapes", {
  set.seed(123)
  landscapes <- create_landscapes(
    n = 10,
    patterns = c(
      "random",
      "bare",
      "dense",
      "clustered",
      "spots",
      "gaps",
      "sharp",
      "diffuse",
      "fingers",
      "bands",
      "labyrinth"
    ),
    width = 50,
    height = 50
  )

  expect_equal(length(landscapes), 10)
})

test_that("create_landscapes returns landscape objects", {
  landscapes <- create_landscapes(
    n = 5,
    width = 20,
    height = 20
  )

  # Check each is a landscape object
  for (i in seq_along(landscapes)) {
    expect_true(is_landscape(landscapes[[i]]))
    expect_s3_class(landscapes[[i]], "landscape")
    expect_s4_class(landscapes[[i]]$data, "SpatRaster")
  }
})

test_that("create_landscapes sets landscape names correctly", {
  set.seed(123)
  landscapes <- create_landscapes(
    n = 5,
    patterns = c("sharp", "random"),
    width = 20,
    height = 20,
    rotation = 0
  )

  # Check that each landscape has its name property set
  for (i in seq_along(landscapes)) {
    expect_equal(landscapes[[i]]$name, names(landscapes)[i])
  }

  # With rotation
  landscapes_rotated <- create_landscapes(
    n = 5,
    patterns = c("sharp"),
    width = 20,
    height = 20,
    rotation = c(0, 45)
  )

  # Check names include rotation info where applicable
  for (i in seq_along(landscapes_rotated)) {
    landscape_name <- landscapes_rotated[[i]]$name
    list_name <- names(landscapes_rotated)[i]

    expect_equal(landscape_name, list_name)

    # If rotation != 0, name should contain "_rot"
    if (landscapes_rotated[[i]]$params$rotation != 0) {
      expect_true(grepl("_rot", landscape_name))
    }
  }
})

test_that("create_landscapes respects pattern selection", {
  set.seed(123)
  # Generate only specific patterns
  landscapes <- create_landscapes(
    n = 10,
    patterns = c("sharp", "diffuse"),
    width = 20,
    height = 20
  )

  # Get all patterns
  patterns <- sapply(landscapes, function(x) x$pattern)
  unique_patterns <- unique(patterns)

  # Should only contain sharp and diffuse
  expect_true(all(unique_patterns %in% c("sharp", "diffuse")))
})

test_that("create_landscapes balances patterns correctly", {
  set.seed(123)
  landscapes <- create_landscapes(
    n = 12,
    patterns = c("sharp", "diffuse", "fingers"),
    width = 20,
    height = 20
  )

  # Get pattern distribution
  patterns <- sapply(landscapes, function(x) x$pattern)
  pattern_counts <- table(patterns)

  # Each type should appear approximately equally (4 each for n=12, 3 patterns)
  expect_equal(length(pattern_counts), 3)
  expect_true(all(pattern_counts >= 3))
  expect_true(all(pattern_counts <= 5))
})

test_that("create_landscapes respects pattern_probs when it's not NULL", {
  # This is harder to test deterministically, but we can check that
  # the function runs without error
  landscapes <- create_landscapes(
    n = 20,
    patterns = c("sharp", "diffuse", "random"),
    width = 20,
    height = 20,
    pattern_probs = c(0.5, 0.3, 0.2)
  )

  expect_equal(length(landscapes), 20)

  # All patterns should be from the selected patterns
  patterns <- sapply(landscapes, function(x) x$pattern)
  expect_true(all(patterns %in% c("sharp", "diffuse", "random")))
})

test_that("create_landscapes handles rotation correctly", {
  set.seed(123)
  # With rotation
  landscapes_rotated <- create_landscapes(
    n = 10,
    width = 50,
    height = 50,
    rotation = c(0, 45, 90),
    patterns = c("sharp", "bands", "fingers", "clustered")
  )

  # Check that some have rotation in their names
  has_rotation <- any(grepl("_rot", names(landscapes_rotated)))
  expect_true(has_rotation)

  # Without rotation
  landscapes_no_rotation <- create_landscapes(
    n = 10,
    width = 50,
    height = 50,
    rotation = 0,
    patterns = c("sharp", "bands", "fingers", "clustered")
  )

  # None should have rotation in their names
  has_rotation <- any(grepl("_rot", names(landscapes_no_rotation)))
  expect_false(has_rotation)

  # All rotation params should be 0
  rotations <- sapply(landscapes_no_rotation, function(x) x$params$rotation)
  expect_true(all(rotations == 0))
})

test_that("create_landscapes never warns about rotation, even mixing patterns", {
  # Mixing rotatable and non-rotatable patterns under one shared `rotation` is
  # the documented, intended way to build a heterogeneous training set (the
  # package's own default is all 11 patterns), so this must stay silent --
  # unlike create_landscape(), which warns for a single explicitly-set pattern
  set.seed(123)

  expect_no_warning(
    create_landscapes(
      n = 4,
      width = 20,
      height = 20,
      patterns = c("bare", "sharp"),
      rotation = 45
    )
  )

  expect_no_warning(
    create_landscapes(
      n = 4,
      width = 20,
      height = 20,
      patterns = c("bare", "sharp")
    )
  )

  expect_no_warning(
    create_landscapes(
      n = 4,
      width = 20,
      height = 20,
      patterns = c("bare", "sharp"),
      rotation = 0
    )
  )

  expect_no_warning(
    create_landscapes(
      n = 4,
      width = 20,
      height = 20,
      patterns = c("sharp", "bands"),
      rotation = 45
    )
  )
})

test_that("create_landscapes respects width and height", {
  set.seed(123)
  landscapes <- create_landscapes(
    patterns = c(
      "random",
      "sharp",
      "diffuse",
      "fingers",
      "clustered",
      "bands",
      "labyrinth"
    ),
    n = 5,
    width = 25,
    height = 35
  )

  # Check dimensions
  for (l in landscapes) {
    expect_equal(terra::ncol(l$data), 25)
    expect_equal(terra::nrow(l$data), 35)
  }
})

test_that("create_landscapes is reproducible with seed", {
  set.seed(456)
  landscapes1 <- create_landscapes(
    n = 10,
    width = 20,
    height = 20
  )
  set.seed(456)
  landscapes2 <- create_landscapes(
    n = 10,
    width = 20,
    height = 20
  )

  # Same patterns in same order
  patterns1 <- sapply(landscapes1, function(x) x$pattern)
  patterns2 <- sapply(landscapes2, function(x) x$pattern)
  expect_equal(patterns1, patterns2)

  # Same names
  expect_equal(names(landscapes1), names(landscapes2))
})

test_that("create_landscapes handles custom params_list", {
  set.seed(123)
  custom_params <- list(
    sharp = list(
      boundary_position = c(0.4, 0.6)
    ),
    random = list(
      veg_prop = c(0.5, 0.7)
    )
  )

  landscapes <- create_landscapes(
    n = 10,
    patterns = c("sharp", "random"),
    width = 20,
    height = 20,
    params_list = custom_params
  )

  # Check that parameters are within the specified ranges
  for (l in landscapes) {
    if (l$pattern == "sharp") {
      expect_true(l$params$boundary_position >= 0.4)
      expect_true(l$params$boundary_position <= 0.6)
    }
    if (l$pattern == "random") {
      expect_true(l$params$veg_prop >= 0.5)
      expect_true(l$params$veg_prop <= 0.7)
    }
  }
})

test_that("create_landscapes handles errors gracefully", {
  set.seed(123)
  # Use parameters that might cause errors in some cases
  # The function should handle errors and continue
  landscapes <- create_landscapes(
    n = 20,
    width = 20,
    height = 20
  )

  # Should still return landscapes (possibly fewer than n if some failed)
  expect_true(length(landscapes) > 0)
  expect_true(length(landscapes) <= 20)
})

test_that("create_landscapes works with all default landscape patterns", {
  set.seed(123)
  landscapes <- create_landscapes(
    n = 24,
    width = 20,
    height = 20
  )

  expect_true(length(landscapes) > 0)

  # Check variety of types
  patterns <- sapply(landscapes, function(x) x$pattern)
  unique_patterns <- unique(patterns)

  # Should have multiple types
  expect_true(length(unique_patterns) > 5)
})

# Parameter merging and validation tests ----------------------------------

test_that("create_landscapes merges partial params with defaults", {
  set.seed(123)

  # Only specify one parameter for clustered
  custom_params <- list(
    clustered = list(n_clusters = c(15, 20))
    # Other clustered params missing - should use defaults
  )

  landscapes <- create_landscapes(
    n = 4,
    patterns = "clustered",
    width = 100,
    height = 100,
    params_list = custom_params
  )

  # Should succeed with merged params
  expect_equal(length(landscapes), 4)

  # Check custom param is in range
  for (l in landscapes) {
    expect_true(l$params$n_clusters >= 15)
    expect_true(l$params$n_clusters <= 20)

    # Check default params are present
    expect_true(!is.null(l$params$cluster_radius))
    expect_true(!is.null(l$params$boundary_position))
  }
})

test_that("create_landscapes fills missing patterns with defaults", {
  set.seed(123)

  custom_params <- list(
    sharp = list(boundary_position = c(0.6, 0.8))
  )

  landscapes <- create_landscapes(
    n = 6,
    patterns = c("sharp", "diffuse"),
    width = 20,
    height = 20,
    params_list = custom_params
  )

  # Should succeed
  expect_equal(length(landscapes), 6)

  # Check both patterns are present
  patterns <- sapply(landscapes, function(x) x$pattern)
  expect_true("sharp" %in% patterns)
  expect_true("diffuse" %in% patterns)

  # Sharp should use custom params
  sharp_landscapes <- landscapes[patterns == "sharp"]
  for (l in sharp_landscapes) {
    expect_true(l$params$boundary_position >= 0.6)
    expect_true(l$params$boundary_position <= 0.8)
  }
})

test_that("create_landscapes removes unknown params without failing", {
  set.seed(123)

  custom_params <- list(
    sharp = list(
      boundary_position = c(0.3, 0.7),
      fake_param = c(1, 2)
    )
  )

  expect_message(
    landscapes <- create_landscapes(
      n = 4,
      patterns = "sharp",
      width = 20,
      height = 20,
      params_list = custom_params
    ),
    "Unknown parameter.*fake_param"
  )

  # Should succeed despite unknown param
  expect_equal(length(landscapes), 4)

  # fake_param should not be in landscape params
  for (l in landscapes) {
    expect_false("fake_param" %in% names(l$params))
  }
})

test_that("create_landscapes rejects invalid parameter values", {
  # boundary_position > 1.0
  expect_error(
    create_landscapes(
      n = 4,
      patterns = "sharp",
      params_list = list(
        sharp = list(boundary_position = c(0.5, 1.5))
      )
    ),
    "exceeds.*maximum"
  )

  # Non-integer for integer param
  expect_error(
    create_landscapes(
      n = 4,
      patterns = "spots",
      params_list = list(
        spots = list(n_spots = c(5.5, 10))
      )
    ),
    "whole number"
  )

  # Min > max
  expect_error(
    create_landscapes(
      n = 4,
      patterns = "diffuse",
      params_list = list(
        diffuse = list(steepness = c(0.9, 0.1))
      )
    ),
    "min.*must be.*max"
  )
})

# Retry mechanism tests ---------------------------------------------------

test_that("create_landscapes retries failed landscapes", {
  set.seed(123)

  # Use a pattern that might occasionally fail with extreme params
  landscapes <- create_landscapes(
    n = 10,
    patterns = "clustered",
    width = 30,
    height = 30,
    max_retries = 5
  )

  # Should still generate landscapes (retries should help)
  expect_true(length(landscapes) >= 8) # Allow some failures
  expect_true(all(sapply(landscapes, is_landscape)))
})

test_that("create_landscapes respects max_retries parameter", {
  set.seed(456)

  # With max_retries = 0, should fail more often
  expect_message(
    # Use a pattern that might occasionally fail with extreme params
    landscapes_no_retry <- create_landscapes(
      n = 10,
      patterns = "clustered",
      width = 30,
      height = 30,
      max_retries = 0
    )
  )

  # With max_retries = 5, should succeed more often
  landscapes_retry <- create_landscapes(
    n = 10,
    patterns = "clustered",
    width = 30,
    height = 30,
    max_retries = 5
  )

  # More retries should result in more successful landscapes
  expect_true(length(landscapes_retry) >= length(landscapes_no_retry))
})

test_that("create_landscapes reports the correct failure count when every landscape fails (M3)", {
  # spot_radius = 20 passes pattern_spots()'s own validation (min 1, no
  # upper bound) but is geometrically impossible at width/height = 10, so
  # every attempt aborts inside create_landscape_spots() deterministically.
  # With zero successes, `all_landscapes` never gets extended by a later
  # assignment, which is exactly the case that hid trailing failures before
  # the fix (list stayed short instead of holding explicit NULLs).
  expect_message(
    landscapes <- create_landscapes(
      n = 3,
      patterns = "spots",
      width = 10,
      height = 10,
      params_list = list(spots = pattern_spots(spot_radius = 20)),
      max_retries = 0
    ),
    "Generated 0/3 landscapes \\(3 failed\\)"
  )
  expect_length(landscapes, 0)
})

test_that("sample_landscape_params samples within ranges", {
  pattern_params <- list(
    boundary_position = c(0.3, 0.7),
    n_clusters = c(5, 10),
    regular_spots = c(TRUE, FALSE)
  )

  # Sample multiple times to check range
  samples <- replicate(
    20,
    {
      sample_landscape_params(
        pattern_params,
        integer_params = c("n_clusters"),
        width = 100,
        height = 100
      )
    },
    simplify = FALSE
  )

  # Check boundary_position is in range
  treeline_vals <- sapply(samples, function(x) x$boundary_position)
  expect_true(all(treeline_vals >= 0.3 & treeline_vals <= 0.7))

  # Check n_clusters is integer in range
  cluster_vals <- sapply(samples, function(x) x$n_clusters)
  expect_true(all(cluster_vals >= 5 & cluster_vals <= 10))
  expect_true(all(cluster_vals == as.integer(cluster_vals)))

  # Check logical sampling
  spot_vals <- sapply(samples, function(x) x$regular_spots)
  expect_true(all(spot_vals %in% c(TRUE, FALSE)))

  # Check width/height added
  expect_true(all(sapply(samples, function(x) x$width == 100)))
  expect_true(all(sapply(samples, function(x) x$height == 100)))
})

test_that("sample_landscape_params always returns a whole number for integer params, even from a fractional range", {
  # A width/height-scaled batch_range can land on non-integer bounds (e.g.
  # bands/band_thickness at height = 20 -> c(0.4, 0.8)) -- seq() starts
  # exactly at `from` rather than rounding to it, so this used to sample a
  # fractional "integer" silently.

  # Range spans no whole number at all
  narrow <- replicate(
    20,
    sample_landscape_params(
      list(n_clusters = c(0.4, 0.8)),
      integer_params = "n_clusters",
      width = 100,
      height = 100
    )$n_clusters
  )
  expect_true(all(narrow == round(narrow)))
  expect_true(all(narrow == narrow[1])) # only one whole number to round to

  # Fractional lower bound, but the range does span whole numbers
  wide <- replicate(
    20,
    sample_landscape_params(
      list(n_clusters = c(2.5, 5)),
      integer_params = "n_clusters",
      width = 100,
      height = 100
    )$n_clusters
  )
  expect_true(all(wide == round(wide)))
  expect_true(all(wide >= 3 & wide <= 5)) # 2.5 itself is not a whole number
})

test_that("try_create_landscape returns NULL on error and reports the cause (M12)", {
  # Invalid parameters that should cause error
  bad_params <- list(
    width = 10,
    height = 10,
    boundary_position = 5 # Invalid - out of range
  )

  # The underlying validation message must reach the user, not be swallowed
  # silently -- otherwise a broken parameter combo is indistinguishable from
  # bad luck (M12).
  expect_message(
    result <- try_create_landscape("sharp", bad_params, 1, 0),
    "boundary_position.*between 0 and 1"
  )

  expect_null(result)
})

test_that("validate_sampled_params aborts loudly on an out-of-bounds sampled value (M23)", {
  # Simulates a spec bug: a sampled draw sitting outside its own min/max --
  # e.g. a batch_range mismatched with the same entry's bounds. veg_prop's
  # spec is min 0, max 1.
  bad_sample <- list(veg_prop = 1.5, width = 50, height = 50)

  expect_error(
    validate_sampled_params(bad_sample, "random"),
    "veg_prop"
  )
})

test_that("validate_sampled_params is silent for a normal sampled draw", {
  good_sample <- sample_landscape_params(
    build_default_params_list(100, 100)[["spots"]],
    get_integer_param_names(),
    100,
    100
  )

  expect_silent(validate_sampled_params(good_sample, "spots"))
})

test_that("try_create_landscape creates valid landscape on success", {
  good_params <- list(
    width = 50,
    height = 50,
    boundary_position = 0.5
  )

  result <- try_create_landscape("sharp", good_params, 42, 90)

  expect_true(is_landscape(result))
  expect_equal(result$pattern, "sharp")
  expect_equal(result$name, "sharp_42_rot90")
  expect_equal(result$params$boundary_position, 0.5)
})

test_that("retry mechanism maintains pattern distribution", {
  set.seed(789)

  landscapes <- create_landscapes(
    n = 30,
    patterns = c("sharp", "diffuse", "clustered"),
    width = 30,
    height = 30,
    max_retries = 5
  )

  # Count patterns
  pattern_counts <- table(sapply(landscapes, function(x) x$pattern))

  # Should be roughly balanced (within 20% of expected)
  expected_per_pattern <- 30 / 3
  expect_true(all(pattern_counts >= expected_per_pattern * 0.8))
  expect_true(all(pattern_counts <= expected_per_pattern * 1.2))
})

test_that("create_landscapes shows appropriate messages", {
  set.seed(123)

  # Successful generation should show success message
  expect_message(
    landscapes <- create_landscapes(
      n = 5,
      patterns = "random",
      width = 20,
      height = 20
    ),
    "Successfully generated all"
  )

  expect_equal(length(landscapes), 5)
})

# Rotation angle validation tests ----------------------------------------

test_that("create_landscapes accepts valid rotation angles", {
  set.seed(123)

  # Vector of angles
  landscapes_vector <- create_landscapes(
    n = 5,
    patterns = "sharp",
    width = 20,
    height = 20,
    rotation = c(0, 45, 90, 135)
  )

  expect_equal(length(landscapes_vector), 5)

  # Single angle
  landscapes_single <- create_landscapes(
    n = 5,
    patterns = "sharp",
    width = 20,
    height = 20,
    rotation = 90
  )

  expect_equal(length(landscapes_single), 5)

  # Edge values
  landscapes_edges <- create_landscapes(
    n = 5,
    patterns = "sharp",
    width = 20,
    height = 20,
    rotation = c(0, 360)
  )

  expect_equal(length(landscapes_edges), 5)
})

test_that("create_landscapes rejects invalid rotation angles", {
  # Negative angle
  expect_error(
    create_landscapes(
      n = 5,
      patterns = "sharp",
      rotation = c(0, -45, 90)
    ),
    "must be between 0 and 360"
  )

  # Angle > 360
  expect_error(
    create_landscapes(
      n = 5,
      patterns = "sharp",
      rotation = c(0, 45, 400)
    ),
    "must be between 0 and 360"
  )

  # Non-numeric
  expect_error(
    create_landscapes(
      n = 5,
      patterns = "sharp",
      rotation = "45"
    ),
    "must be numeric"
  )

  # Contains NA
  expect_error(
    create_landscapes(
      n = 5,
      patterns = "sharp",
      rotation = c(0, NA, 90)
    ),
    "cannot contain NA"
  )
})

# Integer sampling tests --------------------------------------------------

test_that("sample_landscape_params uses efficient integer sampling", {
  pattern_params <- list(
    n_clusters = c(5, 15),
    cluster_radius = c(3, 8)
  )

  # Sample multiple times
  samples <- replicate(
    50,
    sample_landscape_params(
      pattern_params,
      integer_params = c("n_clusters", "cluster_radius"),
      width = 100,
      height = 100
    ),
    simplify = FALSE
  )

  # All values should be integers in range
  cluster_vals <- sapply(samples, function(x) x$n_clusters)
  radius_vals <- sapply(samples, function(x) x$cluster_radius)

  expect_true(all(cluster_vals %% 1 == 0))
  expect_true(all(radius_vals %% 1 == 0))
  expect_true(all(cluster_vals >= 5 & cluster_vals <= 15))
  expect_true(all(radius_vals >= 3 & radius_vals <= 8))

  # Should have some variety (not all the same)
  expect_true(length(unique(cluster_vals)) > 1)
  expect_true(length(unique(radius_vals)) > 1)
})

test_that("sample_landscape_params handles fixed single values", {
  pattern_params <- list(
    boundary_position = 0.5, # Single value, not a range
    n_clusters = c(5, 10), # Range
    invert_landscape = FALSE # Single logical
  )

  samples <- replicate(
    20,
    sample_landscape_params(
      pattern_params,
      integer_params = c("n_clusters"),
      width = 100,
      height = 100
    ),
    simplify = FALSE
  )

  # Fixed values should always be the same
  treeline_vals <- sapply(samples, function(x) x$boundary_position)
  invert_vals <- sapply(samples, function(x) x$invert_landscape)

  expect_true(all(treeline_vals == 0.5))
  expect_true(all(invert_vals == FALSE))

  # Range should vary
  cluster_vals <- sapply(samples, function(x) x$n_clusters)
  expect_true(length(unique(cluster_vals)) > 1)
})

# Continuous frequency sampling (M2) --------------------------------------

test_that("sample_landscape_params draws frequency continuously across its range", {
  set.seed(2026)

  # bands default range: continuous, entirely below 1 (regressed to 0.1 before)
  bands_samples <- replicate(
    100,
    sample_landscape_params(
      list(frequency = c(0.1, 0.3)),
      integer_params = character(0),
      width = 100,
      height = 100
    )$frequency
  )
  expect_true(all(bands_samples >= 0.1 & bands_samples <= 0.3))
  expect_true(length(unique(bands_samples)) > 1)

  # labyrinth default range: fractional (only endpoints appeared before)
  laby_samples <- replicate(
    100,
    sample_landscape_params(
      list(frequency = c(2.5, 3.5)),
      integer_params = character(0),
      width = 100,
      height = 100
    )$frequency
  )
  expect_true(all(laby_samples >= 2.5 & laby_samples <= 3.5))
  expect_true(length(unique(laby_samples)) > 1)
  # Interior values, not just the two endpoints, are reachable
  expect_true(any(laby_samples > 2.5 & laby_samples < 3.5))
})

test_that("sample_landscape_params returns the fixed value for a collapsed integer range", {
  # seq() collapses c(3, 3) to a single value >= 1; sample() must not
  # reinterpret it as sample.int(3).
  samples <- replicate(
    50,
    sample_landscape_params(
      list(octaves = c(3, 3)),
      integer_params = c("octaves"),
      width = 100,
      height = 100
    )$octaves
  )
  expect_true(all(samples == 3))
})

# Retry message tests -----------------------------------------------------

test_that("create_landscapes shows appropriate retry messages", {
  set.seed(999)

  # With low max_retries, might see retry info messages
  # Use a pattern that might occasionally fail
  landscapes <- create_landscapes(
    n = 20,
    patterns = "clustered",
    width = 20,
    height = 20,
    max_retries = 2
  )

  # Should complete successfully (with or without retries)
  expect_true(is.list(landscapes))
  expect_true(length(landscapes) > 0)
})

# Edge case tests ---------------------------------------------------------

test_that("create_landscapes merges NULL params correctly", {
  set.seed(123)

  # NULL params_list should use all defaults
  landscapes <- create_landscapes(
    n = 6,
    patterns = c("sharp", "random"),
    width = 20,
    height = 20,
    params_list = NULL # Explicitly NULL
  )

  expect_equal(length(landscapes), 6)
  expect_true(all(sapply(landscapes, is_landscape)))
})

test_that("create_landscapes handles empty pattern params", {
  set.seed(123)

  # Pattern with empty list should use all defaults
  custom_params <- list(
    sharp = list() # Empty - should use all defaults
  )

  landscapes <- create_landscapes(
    n = 4,
    patterns = "sharp",
    width = 20,
    height = 20,
    params_list = custom_params
  )

  expect_equal(length(landscapes), 4)

  # Should have default parameters applied
  for (l in landscapes) {
    expect_true(!is.null(l$params$boundary_position))
  }
})

test_that("create_landscapes handles failures gracefully", {
  set.seed(999)

  # Use challenging but not impossible parameters
  landscapes <- create_landscapes(
    n = 20,
    patterns = "clustered",
    width = 20,
    height = 20,
    params_list = list(
      clustered = list(
        n_clusters = c(15, 25),
        cluster_radius = c(5, 12)
      )
    ),
    max_retries = 2
  )

  # Should return a list regardless of whether failures occurred
  expect_true(is.list(landscapes))
  expect_true(length(landscapes) > 0)
  expect_true(all(sapply(landscapes, is_landscape)))
})
