# Tests for create_landscape_random
# Random distribution pattern generator

# Validation tests ------------------------------------------------------------

test_that("create_landscape_random validates veg_prop parameter", {
  # Valid veg_prop
  expect_silent(create_landscape_random(
    width = 50,
    height = 50,
    veg_prop = 0.5
  ))
  expect_silent(create_landscape_random(
    width = 50,
    height = 50,
    veg_prop = 0.0
  ))
  expect_silent(create_landscape_random(
    width = 50,
    height = 50,
    veg_prop = 1.0
  ))

  # Invalid veg_prop - non-numeric
  expect_error(
    create_landscape_random(width = 50, height = 50, veg_prop = "half"),
    "`veg_prop` must be between 0 and 1.",
    info = paste("Testing", name, "with non-numeric veg_prop")
  )

  # Invalid veg_prop - negative
  expect_error(
    create_landscape_random(width = 50, height = 50, veg_prop = -0.1),
    "`veg_prop` must be between 0 and 1.",
    info = paste("Testing", name, "with negative veg_prop")
  )

  # Invalid veg_prop - greater than 1
  expect_error(
    create_landscape_random(width = 50, height = 50, veg_prop = 1.5),
    "`veg_prop` must be between 0 and 1.",
    info = paste("Testing", name, "with veg_prop > 1")
  )
})

test_that("create_landscape_random rejects rotation parameter", {
  # rotation is not supported for random landscapes
  expect_error(
    create_landscape_random(
      width = 50,
      height = 50,
      veg_prop = 0.5,
      rotation = 45
    ),
    "unused argument"
  )
})

# Functionality tests ---------------------------------------------------------

test_that("create_landscape_random creates valid random distributions", {
  set.seed(123)

  l <- create_landscape_random(
    width = 50,
    height = 50,
    veg_prop = 0.5
  )

  expect_true(is_landscape(l))
  expect_equal(l$pattern, "random")

  # Check dimensions
  expect_equal(terra::ncol(l$data), 50)
  expect_equal(terra::nrow(l$data), 50)

  # Vegetation proportion should be approximately 0.5
  vals <- terra::values(l$data)
  prop_veg <- sum(vals == 1) / length(vals)
  expect_true(prop_veg > 0.45 && prop_veg < 0.55)
})

test_that("create_landscape_random veg_prop affects density", {
  set.seed(123)

  # Low density
  l_sparse <- create_landscape_random(
    width = 100,
    height = 100,
    veg_prop = 0.2
  )

  # High density
  l_dense <- create_landscape_random(
    width = 100,
    height = 100,
    veg_prop = 0.8
  )

  vals_sparse <- terra::values(l_sparse$data)
  vals_dense <- terra::values(l_dense$data)

  prop_sparse <- sum(vals_sparse == 1) / length(vals_sparse)
  prop_dense <- sum(vals_dense == 1) / length(vals_dense)

  # Dense should have more vegetation than sparse
  expect_true(prop_dense > prop_sparse)
  expect_true(prop_sparse < 0.3)
  expect_true(prop_dense > 0.7)
})

test_that("create_landscape_random stores all params correctly", {
  l <- create_landscape_random(
    width = 75,
    height = 60,
    veg_prop = 0.65
  )

  expect_equal(l$params$width, 75)
  expect_equal(l$params$height, 60)
  expect_equal(l$params$veg_prop, 0.65)

  # Should NOT have rotation parameter
  expect_null(l$params$rotation)
})

test_that("create_landscape_random produces reproducible results with seed", {
  set.seed(456)
  l1 <- create_landscape_random(
    width = 30,
    height = 30,
    veg_prop = 0.5
  )

  set.seed(456)
  l2 <- create_landscape_random(
    width = 30,
    height = 30,
    veg_prop = 0.5
  )

  vals1 <- terra::values(l1$data)
  vals2 <- terra::values(l2$data)
  expect_identical(vals1, vals2)
})

# Edge case tests -------------------------------------------------------------

test_that("create_landscape_random handles edge case veg_prop values", {
  # All vegetation
  l_full <- create_landscape_random(
    width = 20,
    height = 20,
    veg_prop = 1.0
  )
  vals_full <- terra::values(l_full$data)
  expect_true(all(vals_full == 1))

  # No vegetation
  l_empty <- create_landscape_random(
    width = 20,
    height = 20,
    veg_prop = 0.0
  )
  vals_empty <- terra::values(l_empty$data)
  expect_true(all(vals_empty == 0))
})

# Integration tests -----------------------------------------------------------

test_that("create_landscape_random works with extreme parameter combinations", {
  # Very small landscape with no vegetation
  l1 <- create_landscape_random(
    width = 5,
    height = 5,
    veg_prop = 0.0
  )
  expect_true(is_landscape(l1))

  # Very small landscape with all vegetation
  l2 <- create_landscape_random(
    width = 5,
    height = 5,
    veg_prop = 1.0
  )
  expect_true(is_landscape(l2))

  # Very large non-square landscape with extreme veg_prop
  l3 <- create_landscape_random(
    width = 300,
    height = 100,
    veg_prop = 0.95
  )
  expect_true(is_landscape(l3))
})
