test_that("set_landscape_name and set_landscape_class work for single landscape", {
  landscape <- create_landscape("sharp", width = 10, height = 10)

  result_name <- set_landscape_name(landscape, "test_name")
  result_class <- set_landscape_class(landscape, "new_class")

  expect_equal(result_name$name, "test_name")
  expect_equal(result_class$class, "new_class")
  expect_s3_class(result_name, "landscape")
  expect_s3_class(result_class, "landscape")
})

test_that("set_landscape_name and set_landscape_class validate input types", {
  landscape <- create_landscape("sharp", width = 10, height = 10)

  # Non-landscape object
  expect_error(
    set_landscape_name(list(data = 1), "name"),
    "inherits\\(x, \"landscape\"\\)"
  )
  expect_error(
    set_landscape_class(list(data = 1), "class"),
    "inherits\\(x, \"landscape\"\\)"
  )

  # Non-character values
  expect_error(
    set_landscape_name(landscape, 123),
    "is\\.character\\(name\\)"
  )
  expect_error(
    set_landscape_class(landscape, 123),
    "is\\.character\\(class\\)"
  )

  # Multiple values
  expect_error(
    set_landscape_name(landscape, c("name1", "name2")),
    "length\\(name\\) == 1"
  )
  expect_error(
    set_landscape_class(landscape, c("class1", "class2")),
    "length\\(class\\) == 1"
  )
})

test_that("set_landscape_name and set_landscape_class work with multiple landscapes", {
  landscapes <- list(
    create_landscape("sharp", width = 10, height = 10),
    create_landscape("random", width = 10, height = 10)
  )
  names_vec <- c("alpine", "subalpine")
  classes_vec <- c("sharp_treeline", "random_pattern")

  # Using mapply
  result_names <- mapply(
    set_landscape_name,
    landscapes,
    names_vec,
    SIMPLIFY = FALSE
  )
  result_classes <- mapply(
    set_landscape_class,
    landscapes,
    classes_vec,
    SIMPLIFY = FALSE
  )

  expect_equal(result_names[[1]]$name, "alpine")
  expect_equal(result_names[[2]]$name, "subalpine")
  expect_equal(result_classes[[1]]$class, "sharp_treeline")
  expect_equal(result_classes[[2]]$class, "random_pattern")
})
