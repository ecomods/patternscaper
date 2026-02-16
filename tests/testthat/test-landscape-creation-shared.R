# Shared tests for all landscape creation functions ----------------------------

# These tests apply to multiple or all landscape generators and test
# cross-cutting concerns like basic object structure, dimension handling,
# and common parameter validation.

# Basic landscape object creation tests ---------------------------------------
test_that("landscape generators create valid landscape objects", {
  generators <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    fingers = create_landscape_fingers,
    spots = create_landscape_spots,
    gaps = create_landscape_gaps,
    bands = create_landscape_bands,
    clustered = create_landscape_clustered,
    random = create_landscape_random,
    labyrinth = create_landscape_labyrinth
  )

  for (name in names(generators)) {
    gen <- generators[[name]]
    l <- gen(width = 50, height = 50)

    expect_true(is_landscape(l), info = paste("Testing", name))
    expect_s3_class(l, "landscape")
    expect_true(!is.null(l$data), info = paste("Testing", name))
    expect_s4_class(l$data, "SpatRaster")
    expect_equal(l$pattern, name, info = paste("Testing", name))
    expect_true(!is.null(l$params), info = paste("Testing", name))
    expect_equal(terra::ncol(l$data), 50, info = paste("Testing", name))
    expect_equal(terra::nrow(l$data), 50, info = paste("Testing", name))
  }
})

test_that("landscape generators support rotation parameter", {
  generators_with_rotation <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    fingers = create_landscape_fingers,
    spots = create_landscape_spots,
    gaps = create_landscape_gaps,
    bands = create_landscape_bands,
    clustered = create_landscape_clustered
  )

  for (name in names(generators_with_rotation)) {
    gen <- generators_with_rotation[[name]]

    l <- gen(width = 50, height = 50, rotation = 45)

    expect_true(is_landscape(l), info = paste("Testing", name, "with rotation"))
    expect_equal(
      terra::ncol(l$data),
      50,
      info = paste("Testing", name, "dimensions")
    )
    expect_equal(
      terra::nrow(l$data),
      50,
      info = paste("Testing", name, "dimensions")
    )
    expect_equal(
      l$params$rotation,
      45,
      info = paste("Testing", name, "rotation stored")
    )
  }
})

# Shared parameter validation -------------------------------------------------

# Width parameter validation --------------------------------------------------
test_that("landscape generators validate width parameter", {
  generators <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered,
    spots = create_landscape_spots,
    bands = create_landscape_bands,
    gaps = create_landscape_gaps,
    random = create_landscape_random,
    labyrinth = create_landscape_labyrinth
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(width = "50"),
      "must be a positive integer",
      info = paste("Testing", name, "with non-numeric width")
    )

    expect_error(
      gen(width = -10),
      "must be a positive integer",
      info = paste("Testing", name, "with negative width")
    )

    expect_error(
      gen(width = 0),
      "must be a positive integer",
      info = paste("Testing", name, "with zero width")
    )

    expect_error(
      gen(width = 10.5),
      "must be a positive integer",
      info = paste("Testing", name, "with non-integer width")
    )
  }
})

# Height parameter validation -------------------------------------------------
test_that("landscape generators validate height parameter", {
  generators <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered,
    spots = create_landscape_spots,
    gaps = create_landscape_gaps,
    bands = create_landscape_bands,
    gaps = create_landscape_gaps,
    random = create_landscape_random,
    labyrinth = create_landscape_labyrinth
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(height = "50"),
      "must be a positive integer",
      info = paste("Testing", name, "with non-numeric height")
    )

    expect_error(
      gen(height = -10),
      "must be a positive integer",
      info = paste("Testing", name, "with negative height")
    )

    expect_error(
      gen(height = 0),
      "must be a positive integer",
      info = paste("Testing", name, "with zero height")
    )

    expect_error(
      gen(height = 10.5),
      "must be a positive integer",
      info = paste("Testing", name, "with non-integer height")
    )
  }
})

# boundary_position parameter validation --------------------------------------
test_that("landscape generators validate boundary_position parameter", {
  generators <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered,
    bands = create_landscape_bands
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(boundary_position = "0.5"),
      "must be between 0 and 1.",
      info = paste("Testing", name, "with non-numeric boundary_position")
    )

    expect_error(
      gen(boundary_position = -0.1),
      "must be between 0 and 1.",
      info = paste("Testing", name, "with negative boundary_position")
    )

    expect_error(
      gen(boundary_position = 10.5),
      "must be between 0 and 1.",
      info = paste("Testing", name, "with boundary_position > 1")
    )
  }
})

# Rotation parameter validation -----------------------------------------------
test_that("landscape generators validate rotation parameter", {
  generators <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered,
    spots = create_landscape_spots,
    gaps = create_landscape_gaps,
    bands = create_landscape_bands
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(rotation = "45"),
      "must be numeric",
      info = paste("Testing", name, "with non-numeric rotation")
    )

    expect_error(
      gen(rotation = -10),
      "must be between 0 and 360 degrees",
      info = paste("Testing", name, "with negative rotation")
    )

    expect_error(
      gen(rotation = 400),
      "must be between 0 and 360 degrees",
      info = paste("Testing", name, "with rotation > 360")
    )
  }
})

# Pattern-specific validation: random_spots parameter ------------------------
test_that("landscape generators validate random_spots parameter", {
  generators <- list(
    sharp = create_landscape_sharp,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(random_spots = "invalid"),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with non-numeric random_spots")
    )

    expect_error(
      gen(random_spots = c(0.5)),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with length 1 random_spots")
    )

    expect_error(
      gen(random_spots = c(0.5, 0.5, 0.5)),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with length 3 random_spots")
    )

    expect_error(
      gen(random_spots = c(-0.1, 0.5)),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with negative value in random_spots")
    )

    expect_error(
      gen(random_spots = c(0.5, 1.5)),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with value > 1 in random_spots")
    )
  }
})

# Extreme dimensions ----------------------------------------------------------
test_that("landscape generators handle very small landscapes", {
  generators <- list(
    sharp = list(fn = create_landscape_sharp, params = list()),
    diffuse = list(fn = create_landscape_diffuse_treeline, params = list()),
    fingers = list(fn = create_landscape_fingers, params = list()),
    spots = list(fn = create_landscape_spots, params = list(spot_radius = 3)),
    gaps = list(fn = create_landscape_gaps, params = list(spot_radius = 3)),
    random = list(fn = create_landscape_random, params = list(veg_prop = 0.5))
  )

  for (name in names(generators)) {
    gen_info <- generators[[name]]
    params <- c(list(width = 10, height = 10), gen_info$params)

    l <- do.call(gen_info$fn, params)

    expect_true(is_landscape(l), info = paste("Testing", name))
    expect_equal(terra::ncol(l$data), 10, info = paste("Testing", name))
    expect_equal(terra::nrow(l$data), 10, info = paste("Testing", name))
  }
})

test_that("landscape generators handle very large landscapes", {
  generators <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    spots = create_landscape_spots,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered,
    bands = create_landscape_bands,
    gaps = create_landscape_gaps,
    random = create_landscape_random,
    labyrinth = create_landscape_labyrinth
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    l <- gen(width = 500, height = 500)

    expect_true(is_landscape(l), info = paste("Testing", name))
    expect_equal(terra::ncol(l$data), 500, info = paste("Testing", name))
    expect_equal(terra::nrow(l$data), 500, info = paste("Testing", name))
  }
})

test_that("landscape generators handle non-square landscapes without rotation", {
  generators <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    fingers = create_landscape_fingers,
    spots = create_landscape_spots,
    bands = create_landscape_bands,
    clustered = create_landscape_clustered,
    gaps = create_landscape_gaps,
    random = create_landscape_random,
    labyrinth = create_landscape_labyrinth
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    l_wide <- gen(width = 100, height = 50)
    l_tall <- gen(width = 50, height = 100)

    expect_equal(
      terra::ncol(l_wide$data),
      100,
      info = paste("Testing", name, "wide")
    )
    expect_equal(
      terra::nrow(l_wide$data),
      50,
      info = paste("Testing", name, "wide")
    )
    expect_equal(
      terra::ncol(l_tall$data),
      50,
      info = paste("Testing", name, "tall")
    )
    expect_equal(
      terra::nrow(l_tall$data),
      100,
      info = paste("Testing", name, "tall")
    )
  }
})

test_that("landscape generators with rotation handle non-square landscapes", {
  generators_with_rotation <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    fingers = create_landscape_fingers,
    spots = create_landscape_spots,
    bands = create_landscape_bands,
    clustered = create_landscape_clustered,
    gaps = create_landscape_gaps
  )

  for (name in names(generators_with_rotation)) {
    gen <- generators_with_rotation[[name]]

    l_wide_rotated <- gen(width = 100, height = 50, rotation = 45)
    l_tall_rotated <- gen(width = 50, height = 100, rotation = 45)

    # With rotation, dimensions swap
    expect_equal(
      terra::ncol(l_wide_rotated$data),
      100,
      info = paste("Testing", name, "wide rotated")
    )
    expect_equal(
      terra::nrow(l_wide_rotated$data),
      50,
      info = paste("Testing", name, "wide rotated")
    )
    expect_equal(
      terra::ncol(l_tall_rotated$data),
      50,
      info = paste("Testing", name, "tall rotated")
    )
    expect_equal(
      terra::nrow(l_tall_rotated$data),
      100,
      info = paste("Testing", name, "tall rotated")
    )
  }
})

# Extreme rotation angles -----------------------------------------------------
test_that("landscape generators with rotation handle extreme angles", {
  generators_with_rotation <- list(
    sharp = create_landscape_sharp,
    diffuse = create_landscape_diffuse_treeline,
    fingers = create_landscape_fingers,
    spots = create_landscape_spots
  )

  for (name in names(generators_with_rotation)) {
    gen <- generators_with_rotation[[name]]

    l_0 <- gen(rotation = 0)

    l_360 <- gen(rotation = 360)

    expect_true(is_landscape(l_0), info = paste("Testing", name, "rotation 0"))
    expect_true(
      is_landscape(l_360),
      info = paste("Testing", name, "rotation 360")
    )

    # Dimensions should still match
    expect_equal(terra::ncol(l_360$data), 100, info = paste("Testing", name))
    expect_equal(terra::nrow(l_360$data), 100, info = paste("Testing", name))
  }
})
