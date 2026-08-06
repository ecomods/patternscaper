# Tests for the pattern_*() parameter constructors ----------------------------

# Every constructor, paired with the generator it documents. Add a row here
# with each new pattern.
pattern_constructors <- list(
  random = list(build = pattern_random, generate = create_landscape_random),
  bare = list(build = pattern_bare, generate = create_landscape_bare),
  dense = list(build = pattern_dense, generate = create_landscape_dense),
  spots = list(build = pattern_spots, generate = create_landscape_spots)
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

test_that("each constructor tags the pattern it was built for", {
  for (name in names(pattern_constructors)) {
    params <- pattern_constructors[[name]]$build()

    expect_s3_class(params, "landscape_params")
    expect_equal(attr(params, "pattern"), name, info = name)
    expect_length(params, 0)
  }
})

test_that("pattern_spots returns a tagged list of only the supplied parameters", {
  params <- pattern_spots(n_spots = 15, spot_radius = 8)

  expect_s3_class(params, "landscape_params")
  expect_equal(attr(params, "pattern"), "spots")
  expect_equal(names(params), c("n_spots", "spot_radius"))
  expect_equal(params$n_spots, 15)
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

test_that("params produces the same landscape as passing parameters individually", {
  set.seed(42)
  l_params <- create_landscape(
    "spots",
    width = 40,
    height = 40,
    params = pattern_spots(n_spots = 5, spot_radius = 4)
  )

  set.seed(42)
  l_dots <- create_landscape(
    "spots",
    width = 40,
    height = 40,
    n_spots = 5,
    spot_radius = 4
  )

  expect_equal(
    terra::as.matrix(l_params$data, wide = TRUE),
    terra::as.matrix(l_dots$data, wide = TRUE)
  )
  expect_equal(l_params$params, l_dots$params)
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

test_that("the veg_prop constructors match passing the parameter individually", {
  for (name in c("random", "bare", "dense")) {
    build <- pattern_constructors[[name]]$build

    set.seed(3)
    l_params <- create_landscape(
      name,
      width = 20,
      height = 20,
      params = build(veg_prop = 0.3)
    )

    set.seed(3)
    l_dots <- create_landscape(name, width = 20, height = 20, veg_prop = 0.3)

    expect_equal(
      terra::as.matrix(l_params$data, wide = TRUE),
      terra::as.matrix(l_dots$data, wide = TRUE),
      info = name
    )
  }
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

test_that("create_landscape rejects params combined with individual parameters", {
  expect_error(
    create_landscape(
      "spots",
      params = pattern_spots(n_spots = 5),
      n_spots = 10
    ),
    "not both"
  )

  # Also when the two do not overlap -- one route per call, always
  expect_error(
    create_landscape(
      "spots",
      params = pattern_spots(n_spots = 5),
      spot_radius = 4
    ),
    "not both"
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
    n = 2,
    patterns = c("spots", "sharp"),
    width = 40,
    height = 40,
    params_list = list(
      spots = pattern_spots(n_spots = 4, spot_radius = 4),
      sharp = list(boundary_position = 0.4)
    )
  )

  expect_length(landscapes, 2)
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
