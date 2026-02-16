# Tests for landscape parameter validation ---------------------------------

# validate_params_list() tests --------------------------------------------

test_that("validate_params_list accepts valid parameter specifications", {
  params <- list(
    sharp = list(boundary_position = c(0.3, 0.7)),
    diffuse = list(
      steepness = c(0.1, 0.5),
      boundary_position = c(0.2, 0.6)
    )
  )

  expect_silent(
    result <- validate_params_list(params, c("sharp", "diffuse"))
  )
  expect_type(result, "list")
  expect_equal(names(result), c("sharp", "diffuse"))
})

test_that("validate_params_list removes unknown parameters with warning", {
  params <- list(
    sharp = list(
      boundary_position = c(0.3, 0.7),
      fake_param = c(1, 2)
    )
  )

  expect_message(
    result <- validate_params_list(params, "sharp"),
    "Unknown parameter.*fake_param.*will be ignored"
  )

  # fake_param should be removed
  expect_false("fake_param" %in% names(result$sharp))
  expect_true("boundary_position" %in% names(result$sharp))
})

test_that("validate_params_list handles missing patterns", {
  params <- list(
    sharp = list(boundary_position = c(0.3, 0.7))
  )

  # diffuse is missing - should not error (filled with defaults later)
  expect_silent(
    result <- validate_params_list(params, c("sharp", "diffuse"))
  )

  # Only sharp should be in result
  expect_equal(names(result), "sharp")
})

test_that("validate_params_list rejects unknown patterns", {
  params <- list(
    invalid_pattern = list(param = c(1, 2))
  )

  expect_error(
    validate_params_list(params, "invalid_pattern"),
    "Unknown pattern.*invalid_pattern"
  )
})

test_that("validate_params_list rejects non-list pattern params", {
  params <- list(
    sharp = "not a list"
  )

  expect_error(
    validate_params_list(params, "sharp"),
    "must be a list"
  )
})

# Numeric parameter validation --------------------------------------------

test_that("validate_numeric_param accepts valid single values", {
  spec <- list(type = "numeric", min = 0, max = 1)

  expect_silent(
    validate_numeric_param(0.5, "test_param", "test_pattern", spec)
  )
})

test_that("validate_numeric_param accepts valid ranges", {
  spec <- list(type = "numeric", min = 0, max = 1)

  expect_silent(
    validate_numeric_param(c(0.2, 0.8), "test_param", "test_pattern", spec)
  )
})

test_that("validate_numeric_param rejects values below minimum", {
  spec <- list(type = "numeric", min = 0, max = 1)

  expect_error(
    validate_numeric_param(-0.1, "test_param", "test_pattern", spec),
    "below\\s+minimum"
  )
})

test_that("validate_numeric_param rejects values above maximum", {
  spec <- list(type = "numeric", min = 0, max = 1)

  expect_error(
    validate_numeric_param(1.5, "test_param", "test_pattern", spec),
    "1\\.5 exceeds\\s+maximum 1"
  )
})

test_that("validate_numeric_param rejects min >= max", {
  spec <- list(type = "numeric", min = 0, max = 1)

  expect_error(
    validate_numeric_param(c(0.8, 0.2), "test_param", "test_pattern", spec),
    "min.*must be <\\s+max"
  )
})

test_that("validate_numeric_param rejects non-numeric values", {
  spec <- list(type = "numeric", min = 0, max = 1)

  expect_error(
    validate_numeric_param("not numeric", "test_param", "test_pattern", spec),
    "must be numeric"
  )
})

test_that("validate_numeric_param rejects wrong length", {
  spec <- list(type = "numeric", min = 0, max = 1)

  expect_error(
    validate_numeric_param(
      c(0.1, 0.5, 0.9),
      "test_param",
      "test_pattern",
      spec
    ),
    "must be length 1.*or 2"
  )
})

# Integer parameter validation --------------------------------------------

test_that("validate_integer_param accepts whole numbers", {
  spec <- list(type = "integer", min = 1, max = 10)

  expect_silent(
    validate_integer_param(5, "test_param", "test_pattern", spec)
  )

  expect_silent(
    validate_integer_param(5.0, "test_param", "test_pattern", spec)
  )
})

test_that("validate_integer_param rejects non-whole numbers", {
  spec <- list(type = "integer", min = 1, max = 10)

  expect_error(
    validate_integer_param(5.5, "test_param", "test_pattern", spec),
    "whole\\s+number"
  )

  expect_error(
    validate_integer_param(c(1, 5.5), "test_param", "test_pattern", spec),
    "whole\\s+number"
  )
})

test_that("validate_integer_param validates bounds", {
  spec <- list(type = "integer", min = 1, max = 10)

  expect_error(
    validate_integer_param(0, "test_param", "test_pattern", spec),
    "below\\s+minimum"
  )

  expect_error(
    validate_integer_param(11, "test_param", "test_pattern", spec),
    "exceeds\\s+maximum"
  )
})

# Logical parameter validation --------------------------------------------

test_that("validate_logical_param accepts valid logical values", {
  expect_silent(validate_logical_param(TRUE, "test_param", "test_pattern"))
  expect_silent(validate_logical_param(FALSE, "test_param", "test_pattern"))
  expect_silent(validate_logical_param(
    c(TRUE, FALSE),
    "test_param",
    "test_pattern"
  ))
})

test_that("validate_logical_param rejects non-logical values", {
  expect_error(
    validate_logical_param(1, "test_param", "test_pattern"),
    "must be logical"
  )
})

test_that("validate_logical_param warns about identical ranges", {
  expect_message(
    validate_logical_param(c(TRUE, TRUE), "test_param", "test_pattern"),
    "identical min and max"
  )
})
