# Tests for create_landscape() wrapper function -------------------------------

# Validation tests ------------------------------------------------------------

test_that("create_landscape validates pattern input", {
  # Short match strings throughout: cli wraps long messages at console width,
  # so a phrase can be split across lines.

  # Invalid type - not a character
  expect_error(
    create_landscape(123),
    "must be a character vector"
  )

  # Multiple patterns provided -- points at the function that takes several
  expect_error(
    create_landscape(c("sharp", "diffuse")),
    "create_landscapes"
  )

  # Invalid pattern name
  expect_error(
    create_landscape("invalid_pattern"),
    "must be one of"
  )
})

test_that("create_landscape requires a pattern", {
  # pattern has no default: omitting it is an error, not a silent "random"
  expect_error(
    create_landscape(),
    "not absent"
  )
})

test_that("create_landscape suggests a correction but does not partial match", {
  # arg_match() offers the near miss ...
  expect_error(
    create_landscape("labyrinths"),
    "Did you mean"
  )

  # ... but an unambiguous prefix is still rejected, unlike match.arg()
  expect_error(
    create_landscape("lab"),
    "must be one of"
  )
})

test_that("create_landscape propagates errors from underlying functions", {
  # For example, invalid parameters should cause errors
  expect_error(
    create_landscape("sharp", width = -10, height = 50)
  )
})

# Functionality tests ---------------------------------------------------------

test_that("create_landscape creates correct landscape types", {
  set.seed(123)
  # Test each pattern creates the correct pattern
  expect_equal(
    create_landscape("random", width = 10, height = 10)$pattern,
    "random"
  )
  expect_equal(
    create_landscape("sharp", width = 10, height = 10)$pattern,
    "sharp"
  )
  expect_equal(
    create_landscape("diffuse", width = 10, height = 10)$pattern,
    "diffuse"
  )
  expect_equal(
    create_landscape("fingers", width = 10, height = 10)$pattern,
    "fingers"
  )
  expect_equal(
    create_landscape(
      "clustered",
      width = 10,
      height = 10,
      params = pattern_clustered(cluster_radius = 1)
    )$pattern,
    "clustered"
  )
  expect_equal(
    create_landscape("bands", width = 10, height = 10)$pattern,
    "bands"
  )
  expect_equal(
    create_landscape(
      "spots",
      width = 10,
      height = 10,
      params = pattern_spots(spot_radius = 1)
    )$pattern,
    "spots"
  )
  expect_equal(
    create_landscape(
      "gaps",
      width = 10,
      height = 10,
      params = pattern_gaps(spot_radius = 1)
    )$pattern,
    "gaps"
  )
  expect_equal(
    create_landscape("labyrinth", width = 10, height = 10)$pattern,
    "labyrinth"
  )
})

test_that("create_landscape passes parameters correctly", {
  # Test that custom parameters are passed through
  l <- create_landscape(
    "sharp",
    width = 30,
    height = 40,
    params = pattern_sharp(boundary_position = 0.7)
  )

  expect_equal(terra::ncol(l$data), 30)
  expect_equal(terra::nrow(l$data), 40)
  expect_equal(l$params$boundary_position, 0.7)

  # Test that name parameter is set correctly
  l_named <- create_landscape(
    "sharp",
    width = 30,
    height = 40,
    name = "my_landscape"
  )

  expect_equal(l_named$name, "my_landscape")

  # Test that name is NULL when not provided
  expect_true(is.na(l$name) || is.null(l$name))
})

test_that("create_landscape returns valid landscape objects", {
  # Test a few different patterns
  patterns_to_test <- c("random", "sharp", "diffuse", "bands")

  for (pattern in patterns_to_test) {
    l <- create_landscape(pattern, width = 20, height = 20)

    expect_true(is_landscape(l), label = paste("Pattern:", pattern))
    expect_s3_class(l, "landscape")
    expect_s4_class(l$data, "SpatRaster")
    expect_true(!is.null(l$params))
  }
})

test_that("create_landscape handles rotation parameter", {
  l <- create_landscape("sharp", width = 50, height = 50, rotation = 45)

  expect_true(is_landscape(l))
  expect_equal(l$params$rotation, 45)
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)
})

test_that("pattern_label relabels without changing the landscape", {
  set.seed(8)
  l_labelled <- create_landscape(
    "sharp",
    width = 30,
    height = 30,
    pattern_label = "ecotone"
  )

  set.seed(8)
  l_plain <- create_landscape("sharp", width = 30, height = 30)

  expect_equal(l_labelled$pattern, "ecotone")
  expect_equal(l_plain$pattern, "sharp")
  expect_equal(
    terra::as.matrix(l_labelled$data, wide = TRUE),
    terra::as.matrix(l_plain$data, wide = TRUE)
  )
})

test_that("pattern_label and name set different fields", {
  l <- create_landscape(
    "spots",
    width = 50,
    height = 50,
    name = "site_a",
    pattern_label = "patchy"
  )

  expect_equal(l$pattern, "patchy")
  expect_equal(l$name, "site_a")
})

test_that("every rotatable pattern accepts rotation", {
  for (pattern in c("sharp", "diffuse", "fingers", "clustered", "bands")) {
    l <- create_landscape(pattern, width = 50, height = 50, rotation = 45)

    expect_equal(l$params$rotation, 45, info = pattern)
  }
})

test_that("patterns without rotation ignore it, with a warning", {
  for (pattern in c("random", "bare", "dense", "spots", "gaps", "labyrinth")) {
    set.seed(5)
    expect_warning(
      create_landscape(pattern, width = 50, height = 50, rotation = 45),
      "rotation.*ignored",
      info = pattern
    )

    set.seed(5)
    l_rotation <- suppressWarnings(
      create_landscape(pattern, width = 50, height = 50, rotation = 45)
    )

    set.seed(5)
    l_plain <- create_landscape(pattern, width = 50, height = 50)

    expect_equal(
      terra::as.matrix(l_rotation$data, wide = TRUE),
      terra::as.matrix(l_plain$data, wide = TRUE),
      info = pattern
    )
  }
})

test_that("create_landscape does not warn about rotation when left unset or zero", {
  for (pattern in c("random", "bare", "dense", "spots", "gaps", "labyrinth")) {
    expect_no_warning(create_landscape(pattern, width = 50, height = 50))
    expect_no_warning(
      create_landscape(pattern, width = 50, height = 50, rotation = 0)
    )
  }

  # Rotatable patterns never trigger the ignored-rotation warning either
  for (pattern in c("sharp", "diffuse", "fingers", "clustered", "bands")) {
    expect_no_warning(
      create_landscape(pattern, width = 50, height = 50, rotation = 45)
    )
  }
})

test_that("leaving rotation unset generates the same landscape as before", {
  set.seed(11)
  l_unset <- create_landscape("sharp", width = 30, height = 30)

  set.seed(11)
  l_zero <- create_landscape("sharp", width = 30, height = 30, rotation = 0)

  expect_equal(
    terra::as.matrix(l_unset$data, wide = TRUE),
    terra::as.matrix(l_zero$data, wide = TRUE)
  )
})
