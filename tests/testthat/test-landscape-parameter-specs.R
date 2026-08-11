# Regression coverage for the canonical parameter spec table -----------------

# valid_patterns() is the single source for which patterns exist. Three other
# places name patterns and none of them can be derived from it: the spec table
# keys are parameter metadata, create_landscapes()'s default is a formal (kept
# literal so the help page's usage section lists the patterns), and rotation is
# a property of a subset. Pin them together so none can drift unnoticed.

test_that("everything that names patterns agrees with valid_patterns()", {
  expect_setequal(names(landscape_param_specs()), valid_patterns())

  expect_equal(
    eval(formals(create_landscapes)$patterns),
    valid_patterns()
  )

  expect_true(all(rotatable_patterns() %in% valid_patterns()))
})

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
      radius_noise_fraction = c(0, 0.2),
      regular_spots = c(TRUE, FALSE),
      invert_landscape = c(FALSE)
    ),
    gaps = list(
      n_spots = c(5, 10),
      spot_radius = c(10, 20),
      spot_radius_sd = c(0, 2),
      radius_noise_fraction = c(0, 0.2),
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

  # gaps has no invert_landscape entry anywhere: create_landscape_gaps() has
  # no such formal (hardcoded TRUE internally), so it's neither a valid
  # override nor part of the default batch distribution.
  expect_false("invert_landscape" %in% names(valid_specs$gaps))
  expect_false("invert_landscape" %in% names(defaults$gaps))
})

# radius_noise_fraction validation (Step 4 fix) -------------------------------

test_that("radius_noise_fraction is no longer silently stripped for spots/gaps", {
  landscapes_spots <- create_landscapes(
    n = 1,
    patterns = "spots",
    params_list = list(spots = list(radius_noise_fraction = c(0.1, 0.3)))
  )
  expect_true(
    landscapes_spots[[1]]$params$radius_noise_fraction >= 0.1 &&
      landscapes_spots[[1]]$params$radius_noise_fraction <= 0.3
  )

  landscapes_gaps <- create_landscapes(
    n = 1,
    patterns = "gaps",
    params_list = list(gaps = list(radius_noise_fraction = c(0.1, 0.3)))
  )
  expect_true(
    landscapes_gaps[[1]]$params$radius_noise_fraction >= 0.1 &&
      landscapes_gaps[[1]]$params$radius_noise_fraction <= 0.3
  )
})

test_that("radius_noise_fraction is part of default batch sampling for spots/gaps", {
  result <- build_default_params_list(width = 100, height = 100)

  expect_equal(result$spots$radius_noise_fraction, c(0, 0.2))
  expect_equal(result$gaps$radius_noise_fraction, c(0, 0.2))
})

# gaps invert_landscape removal (Step 5 fix) -----------------------------------

test_that("invert_landscape for gaps is rejected as unknown instead of silently crashing the generator", {
  expect_message(
    landscapes <- create_landscapes(
      n = 1,
      patterns = "gaps",
      params_list = list(gaps = list(invert_landscape = FALSE))
    ),
    "Unknown parameter.*invert_landscape.*will be ignored"
  )

  # The pattern still generates successfully with the unknown param dropped,
  # rather than failing silently inside create_landscape_gaps() and being
  # swallowed by try_create_landscape()'s tryCatch.
  expect_length(landscapes, 1)
  expect_equal(landscapes[[1]]$pattern, "gaps")
})

# integer_params derivation (Step 6 fix) ---------------------------------------

test_that("get_integer_param_names matches the former hardcoded set, minus the two dead entries", {
  expect_equal(
    sort(get_integer_param_names()),
    sort(c(
      "n_clusters",
      "cluster_radius",
      "band_thickness",
      "band_spacing",
      "n_spots",
      "spot_radius",
      "octaves",
      "amplitude"
    ))
  )

  # nhills/nbands were dead entries matching no current parameter
  expect_false("nhills" %in% get_integer_param_names())
  expect_false("nbands" %in% get_integer_param_names())
})

# Spec/formals drift guard -----------------------------------------------------

# The spec table and the generator formals are maintained separately, and every
# drift found so far was a parameter present in one but not the other.
# Comparing them directly makes the next one fail here instead of
# waiting to be noticed.
#
# rotation is the one legitimate exception: a formal of the five
# rotation-capable generators, deliberately absent from the spec because
# create_landscapes() supplies it from its own argument instead of sampling it
# per pattern.

test_that("spec parameter names match the generator formals for all 11 patterns", {
  generators <- list(
    random = create_landscape_random,
    bare = create_landscape_bare,
    dense = create_landscape_dense,
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered,
    bands = create_landscape_bands,
    spots = create_landscape_spots,
    gaps = create_landscape_gaps,
    labyrinth = create_landscape_labyrinth
  )

  specs <- landscape_param_specs()
  not_pattern_params <- c("width", "height", "rotation")

  expect_setequal(names(specs), names(generators))

  for (pattern in names(generators)) {
    formal_names <- setdiff(
      names(formals(generators[[pattern]])),
      not_pattern_params
    )
    spec_names <- names(specs[[pattern]])

    expect_equal(
      setdiff(formal_names, spec_names),
      character(0),
      info = paste(
        pattern,
        "- formal(s) missing from the spec, so create_landscapes() drops them"
      )
    )
    expect_equal(
      setdiff(spec_names, formal_names),
      character(0),
      info = paste(
        pattern,
        "- spec entr(ies) with no matching formal, so the generator errors"
      )
    )
  }
})

# Spec bounds vs. generator bounds -------------------------------------------

# The spec's min/max gate what a user may supply; each generator then applies
# its own checks. When the two disagree, the constructor accepts a value the
# generator refuses and in create_landscapes() that error is swallowed by
# try_create_landscape() into a quietly shorter batch. This caught diffuse's
# steepness (spec said Inf, generator capped at 1) and four exclusive minimums.

test_that("spec bounds match the bounds each generator enforces", {
  specs <- landscape_param_specs()

  # Generous canvas: some patterns fail on geometry at the default size, which
  # is a different (legitimate) error -- see the message check below
  width <- 200
  height <- 200

  for (pattern in names(specs)) {
    build <- get(paste0("pattern_", pattern))

    for (name in names(specs[[pattern]])) {
      spec <- specs[[pattern]][[name]]
      if (identical(spec$type, "logical")) {
        next
      }

      # Values the spec declares legal, just inside each bound
      probes <- c(
        if (isTRUE(spec$exclusive_min)) spec$min + 0.01 else spec$min,
        if (is.finite(spec$max)) spec$max else 5
      )

      for (value in probes) {
        params <- tryCatch(
          do.call(build, setNames(list(value), name)),
          error = function(e) e
        )

        # The constructor must accept what the spec declares legal
        expect_false(
          inherits(params, "error"),
          info = paste(
            pattern,
            name,
            "- constructor rejects legal value",
            value
          )
        )
        if (inherits(params, "error")) {
          next
        }

        # Extreme-but-legal values legitimately warn about geometry; only
        # errors are of interest here
        first_line <- suppressWarnings(tryCatch(
          {
            create_landscape(
              pattern,
              width = width,
              height = height,
              params = params
            )
            NA_character_
          },
          error = function(e) strsplit(conditionMessage(e), "\n")[[1]][1]
        ))

        # A geometry failure names no parameter on its first line; a bounds
        # complaint names the one it is rejecting
        expect_false(
          !is.na(first_line) && grepl(name, first_line, fixed = TRUE),
          info = paste(pattern, name, "=", value, "->", first_line)
        )
      }
    }
  }
})
