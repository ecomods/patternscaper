# Tests for the pattern_*() parameter constructors ----------------------------

# Every constructor, paired with the generator it documents. Add a row here
# with each new pattern.
pattern_constructors <- list(
  random = list(build = pattern_random, generate = create_landscape_random),
  bare = list(build = pattern_bare, generate = create_landscape_bare),
  dense = list(build = pattern_dense, generate = create_landscape_dense),
  sharp = list(build = pattern_sharp, generate = create_landscape_sharp),
  diffuse = list(build = pattern_diffuse, generate = create_landscape_diffuse),
  fingers = list(build = pattern_fingers, generate = create_landscape_fingers),
  clustered = list(
    build = pattern_clustered,
    generate = create_landscape_clustered
  ),
  bands = list(build = pattern_bands, generate = create_landscape_bands),
  spots = list(build = pattern_spots, generate = create_landscape_spots),
  gaps = list(build = pattern_gaps, generate = create_landscape_gaps),
  labyrinth = list(
    build = pattern_labyrinth,
    generate = create_landscape_labyrinth
  )
)

# Constructor/generator default drift guard -----------------------------------

# The constructors repeat the generators' defaults so that the help page shows
# real values instead of NULL. Nothing else keeps the two copies in step, and a
# constructor showing a default the generator does not use would document a
# value the user never gets.

test_that("constructor defaults match the generator defaults", {
  for (name in names(pattern_constructors)) {
    pair <- pattern_constructors[[name]]

    # eval() rather than a plain comparison: one default in the package is the
    # expression 2 * pi / 100, not a literal
    built <- lapply(formals(pair$build), eval, envir = baseenv())
    generated <- lapply(
      formals(pair$generate)[names(built)],
      eval,
      envir = baseenv()
    )

    expect_equal(built, generated, info = name)
  }
})

test_that("every pattern has a constructor", {
  expect_setequal(
    names(pattern_constructors),
    names(landscape_param_specs())
  )
})

test_that("each constructor exposes exactly its pattern's parameters", {
  # The spec is already checked against the generator formals elsewhere, so
  # this closes the triangle: nothing in the spec is unreachable from a
  # constructor, and no constructor offers a parameter that does not exist.
  specs <- landscape_param_specs()

  for (name in names(pattern_constructors)) {
    formal_names <- names(formals(pattern_constructors[[name]]$build))
    spec_names <- names(specs[[name]])

    expect_equal(
      setdiff(spec_names, formal_names),
      character(0),
      info = paste(name, "- spec parameter(s) with no constructor argument")
    )
    expect_equal(
      setdiff(formal_names, spec_names),
      character(0),
      info = paste(name, "- constructor argument(s) that are not parameters")
    )
  }
})

test_that("the generated ranges section covers every parameter", {
  # The section is built from the spec so it cannot drift from the bounds
  # actually enforced or the ranges actually sampled. That only holds if every
  # parameter reaches it.
  specs <- landscape_param_specs()

  for (name in names(pattern_constructors)) {
    rd <- rd_param_ranges(name)

    for (param in names(specs[[name]])) {
      expect_true(
        any(grepl(paste0("\\code{", param, "} \\tab"), rd, fixed = TRUE)),
        info = paste(name, "-", param)
      )
    }
  }
})

test_that("radius_noise_fraction is described with its sampled range", {
  rd <- rd_param_ranges("spots")
  noise <- grep("radius_noise_fraction", rd, value = TRUE)

  expect_match(noise, "0 to 0.2", fixed = TRUE)
})

test_that("the ranges section reports the bounds a user is held to", {
  # Inclusive, exclusive-minimum and unbounded-above all read differently, and
  # a page that got these wrong would send a user to a value the generator
  # rejects
  veg <- grep("veg_prob", rd_param_ranges("random"), value = TRUE)
  expect_match(veg, "0 to 1", fixed = TRUE)

  elong <- grep("elongation_x", rd_param_ranges("clustered"), value = TRUE)
  expect_match(elong, "greater than 0", fixed = TRUE)

  zone <- grep("cluster_zone", rd_param_ranges("clustered"), value = TRUE)
  expect_match(zone, "greater than 0, up to 1", fixed = TRUE)

  spots <- grep("n_spots", rd_param_ranges("spots"), value = TRUE)
  expect_match(spots, "1 or more", fixed = TRUE)

  regular <- grep("regular_spots", rd_param_ranges("spots"), value = TRUE)
  expect_match(regular, "TRUE or FALSE", fixed = TRUE)
})

test_that("pattern_gaps has no invert_landscape, unlike pattern_spots", {
  # Inverting is what makes gaps gaps: create_landscape_gaps() hardcodes it,
  # so exposing it would let a caller turn gaps back into spots
  expect_false("invert_landscape" %in% names(formals(pattern_gaps)))
  expect_true("invert_landscape" %in% names(formals(pattern_spots)))
})

test_that("each constructor tags the pattern it was built for", {
  for (name in names(pattern_constructors)) {
    params <- pattern_constructors[[name]]$build()

    expect_s3_class(params, "landscape_params")
    expect_equal(attr(params, "pattern"), name, info = name)
    expect_length(params, 0)
  }
})

test_that("pattern_spots drops unsupplied parameters instead of filling defaults", {
  # The signature carries the generators' defaults so they show up in the help
  # page, but recording them would override the generator -- and in the batch
  # path it would replace a sampling range with a fixed value.
  expect_length(pattern_spots(), 0)
  expect_false("spot_radius" %in% names(pattern_spots(n_spots = 5)))
})

test_that("pattern_spots keeps a value that happens to equal the default", {
  # Passing the default explicitly is not the same as leaving it unset: in
  # create_landscapes() the first fixes the parameter, the second samples it.
  expect_equal(pattern_spots(n_spots = 15)$n_spots, 15)
})

test_that("pattern_spots validates values against the parameter spec", {
  expect_error(pattern_spots(radius_noise_fraction = 1.5), "exceeds maximum")
  expect_error(pattern_spots(n_spots = 2.5), "whole number")
  expect_error(pattern_spots(regular_spots = "yes"), "must be logical")
})

test_that("pattern_spots rejects names that are not spots parameters", {
  expect_error(pattern_spots(nspots = 5), "unused argument")
  expect_error(pattern_spots(boundary_position = 0.5), "unused argument")
})

test_that("pattern_spots accepts ranges for create_landscapes", {
  params <- pattern_spots(n_spots = c(5, 15))

  expect_equal(params$n_spots, c(5, 15))
})

# create_landscape() ----------------------------------------------------------

# This compares the constructor route against calling the generator directly.
# That is the guarantee that matters: the values a user puts into pattern_*()
# reach the generator unchanged. Until 0.3.0 it compared against passing
# parameters through ..., which no longer exists.

test_that("every constructor reaches its generator unchanged", {
  cases <- list(
    random = list(veg_prob = 0.3),
    bare = list(veg_prob = 0.3),
    dense = list(veg_prob = 0.3),
    sharp = list(boundary_position = 0.3),
    diffuse = list(steepness = 0.3, boundary_position = 0.4),
    fingers = list(sine_length_mean = 15, sine_height_mean = 6),
    clustered = list(n_clusters = 6, cluster_radius = 4),
    bands = list(band_thickness = 4, band_spacing = 12),
    spots = list(n_spots = 5, spot_radius = 4),
    gaps = list(n_gaps = 4, gap_radius = 6),
    labyrinth = list(frequency = 3.5, octaves = 3)
  )

  # Adding a pattern to the fixture fails here until it gets a case
  expect_setequal(names(cases), names(pattern_constructors))

  for (name in names(cases)) {
    pair <- pattern_constructors[[name]]

    set.seed(9)
    l_params <- create_landscape(
      name,
      width = 60,
      height = 60,
      params = do.call(pair$build, cases[[name]])
    )

    set.seed(9)
    l_direct <- do.call(
      pair$generate,
      c(list(width = 60, height = 60), cases[[name]])
    )

    expect_equal(
      terra::as.matrix(l_params$data, wide = TRUE),
      terra::as.matrix(l_direct$data, wide = TRUE),
      info = name
    )
    expect_equal(l_params$params, l_direct$params, info = name)
  }
})

test_that("create_landscape leaves unset parameters at the generator defaults", {
  set.seed(1)
  l_empty <- create_landscape(
    "spots",
    width = 40,
    height = 40,
    params = pattern_spots()
  )

  set.seed(1)
  l_default <- create_landscape("spots", width = 40, height = 40)

  expect_equal(
    terra::as.matrix(l_empty$data, wide = TRUE),
    terra::as.matrix(l_default$data, wide = TRUE)
  )
})

test_that("params combines with rotation, which is not a pattern parameter", {
  l <- create_landscape(
    "sharp",
    width = 40,
    height = 40,
    params = pattern_sharp(boundary_position = 0.3),
    rotation = 45
  )

  expect_equal(l$params$boundary_position, 0.3)
  expect_equal(l$params$rotation, 45)
})

test_that("create_landscape rejects params built for another pattern", {
  expect_error(
    create_landscape("bands", params = pattern_spots(n_spots = 5)),
    "was built for pattern"
  )
})

test_that("create_landscape rejects a range, which it cannot sample", {
  expect_error(
    create_landscape("spots", params = pattern_spots(n_spots = c(5, 15))),
    "single value per parameter"
  )
})

test_that("create_landscape rejects pattern parameters passed directly", {
  # params is the only route -- create_landscape() has no ... to absorb them
  expect_error(
    create_landscape("spots", n_spots = 5),
    "unused argument"
  )
})

test_that("create_landscape rejects a plain list passed as params", {
  expect_error(
    create_landscape("spots", params = list(n_spots = 5)),
    "must come from"
  )
})


# create_landscapes() ---------------------------------------------------------

test_that("params_list accepts constructor output", {
  set.seed(7)
  landscapes <- create_landscapes(
    n = 2,
    patterns = "spots",
    width = 40,
    height = 40,
    params_list = list(spots = pattern_spots(n_spots = 4, spot_radius = 4))
  )

  expect_length(landscapes, 2)
  expect_equal(landscapes[[1]]$params$n_spots, 4)
})

test_that("params_list treats a constructor range as a range", {
  set.seed(7)
  landscapes <- create_landscapes(
    n = 3,
    patterns = "spots",
    width = 40,
    height = 40,
    params_list = list(spots = pattern_spots(n_spots = c(3, 6), spot_radius = 4))
  )

  drawn <- vapply(landscapes, \(l) l$params$n_spots, numeric(1))

  expect_true(all(drawn >= 3 & drawn <= 6))
})

test_that("params_list accepts constructor output and plain lists together", {
  set.seed(7)
  landscapes <- create_landscapes(
    n = 6,
    patterns = c("spots", "sharp"),
    width = 40,
    height = 40,
    params_list = list(
      spots = pattern_spots(n_spots = 4, spot_radius = 4),
      sharp = list(boundary_position = 0.4)
    )
  )

  expect_length(landscapes, 6)

  # Both routes have to actually take effect, not just be accepted
  for (l in landscapes) {
    if (l$pattern == "spots") {
      expect_equal(l$params$n_spots, 4)
    } else {
      expect_equal(l$params$boundary_position, 0.4)
    }
  }
})

test_that("params_list rejects constructor output under the wrong pattern", {
  expect_error(
    create_landscapes(
      n = 1,
      patterns = "bands",
      params_list = list(bands = pattern_spots(n_spots = 5))
    ),
    "were built by"
  )
})
