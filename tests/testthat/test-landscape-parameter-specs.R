# Regression coverage for the canonical parameter spec table -----------------

# build_default_params_list() feeds sample_landscape_params(), which draws
# RNG values in list order -- so both the key order AND the literal values
# below must stay pinned exactly. These are the same values create_landscapes()
# used before the spec table was introduced (see git history of
# R/landscape_create.R's former inline default_params_list).

test_that("build_default_params_list preserves exact order and values for all 11 patterns", {
  result <- build_default_params_list(width = 100, height = 100)

  expected <- list(
    random = list(veg_prop = c(0.1, 0.9)),
    bare = list(veg_prop = c(0, 0.1)),
    dense = list(veg_prop = c(0.8, 1)),
    sharp = list(boundary_position = c(0.2, 0.8)),
    diffuse = list(
      steepness = c(0.1, 1),
      boundary_position = c(0.1, 0.4)
    ),
    fingers = list(
      boundary_position = c(0.3, 0.6),
      sine_length_mean = c(20, 50),
      sine_length_sd = c(10, 50),
      sine_height_mean = c(5, 20),
      sine_height_sd = c(5, 25)
    ),
    clustered = list(
      boundary_position = c(0.4, 0.6),
      n_clusters = c(5, 12),
      cluster_radius = c(5, 10),
      scatter_zone_prop = c(0.2, 1),
      elongation_x = c(0.5, 1.5),
      elongation_y = c(0.5, 1.5)
    ),
    bands = list(
      boundary_position = c(0.3, 0.5),
      band_zone_prop = c(0.3, 0.6),
      band_thickness = c(2, 4),
      band_spacing = c(10, 20),
      frequency = c(0.1, 0.3),
      amplitude = c(0, 6),
      noise_sd = c(0, 1)
    ),
    spots = list(
      n_spots = c(5, 10),
      spot_radius = c(10, 20),
      spot_radius_sd = c(0, 2),
      regular_spots = c(TRUE, FALSE),
      invert_landscape = c(FALSE)
    ),
    gaps = list(
      n_spots = c(5, 10),
      spot_radius = c(10, 20),
      spot_radius_sd = c(0, 2),
      regular_spots = c(TRUE, FALSE)
    ),
    labyrinth = list(
      frequency = c(2.5, 3.5),
      veg_threshold = c(0.45, 0.55),
      band_fuzziness = c(0.06, 0.25),
      octaves = c(2, 4)
    )
  )

  expect_equal(names(result), names(expected))

  for (pattern in names(expected)) {
    expect_equal(
      names(result[[pattern]]),
      names(expected[[pattern]]),
      info = paste("Parameter order for", pattern)
    )
    expect_equal(
      result[[pattern]],
      expected[[pattern]],
      info = paste("Parameter values for", pattern)
    )
  }
})

test_that("gaps has no invert_landscape entry in default batch ranges", {
  result <- build_default_params_list(width = 100, height = 100)

  expect_false("invert_landscape" %in% names(result$gaps))
})

test_that("width/height-dependent batch ranges scale correctly", {
  result <- build_default_params_list(width = 200, height = 50)

  expect_equal(result$fingers$sine_length_mean, c(0.2, 0.5) * 200)
  expect_equal(result$fingers$sine_height_mean, c(0.05, 0.2) * 50)
  expect_equal(result$bands$band_thickness, c(0.02, 0.04) * 50)
  expect_equal(result$spots$spot_radius, c(0.1, 0.2) * 200)
})

test_that("get_valid_param_specs still matches build_default_params_list's key set (validation-only params aside)", {
  valid_specs <- get_valid_param_specs()
  defaults <- build_default_params_list(width = 100, height = 100)

  for (pattern in names(defaults)) {
    # Every param with a default batch range must also be a recognized,
    # validatable parameter for that pattern.
    expect_true(
      all(names(defaults[[pattern]]) %in% names(valid_specs[[pattern]])),
      info = paste("Pattern", pattern)
    )
  }

  # gaps$invert_landscape is the one documented exception: valid for
  # validation, but not part of the default batch distribution.
  expect_true("invert_landscape" %in% names(valid_specs$gaps))
  expect_false("invert_landscape" %in% names(defaults$gaps))
})
