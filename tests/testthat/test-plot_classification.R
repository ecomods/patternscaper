# Test plot_classified_landscapes input validation -----------------------

test_that("plot_classified_landscapes accepts valid inputs", {
  landscapes <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("diffuse", width = 20, height = 20)
  )

  classification <- data.frame(
    landscape_id = 1:2,
    actual_class = c("sharp", "diffuse"),
    predicted_class = c("sharp", "sharp"),
    confidence = c(0.95, 0.65)
  )

  result <- plot_classified_landscapes(classification, landscapes)
  expect_s3_class(result, "patchwork")
})

test_that("plot_classified_landscapes rejects non-data.frame classification", {
  landscapes <- list(
    create_landscape("sharp", width = 20, height = 20)
  )

  expect_error(
    plot_classified_landscapes(list(a = 1), landscapes),
    class = "rlang_error"
  )

  expect_error(
    plot_classified_landscapes("not a dataframe", landscapes),
    class = "rlang_error"
  )

  expect_error(
    plot_classified_landscapes(NULL, landscapes),
    class = "rlang_error"
  )
})

test_that("plot_classified_landscapes rejects classification with missing columns", {
  landscapes <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("diffuse", width = 20, height = 20)
  )

  # Missing landscape_id
  expect_error(
    plot_classified_landscapes(
      data.frame(
        actual_class = c("sharp", "diffuse"),
        predicted_class = c("sharp", "sharp"),
        confidence = c(0.95, 0.65)
      ),
      landscapes
    ),
    "Invalid classification results"
  )

  # Missing actual_class
  expect_error(
    plot_classified_landscapes(
      data.frame(
        landscape_id = 1:2,
        predicted_class = c("sharp", "sharp"),
        confidence = c(0.95, 0.65)
      ),
      landscapes
    ),
    "Invalid classification results"
  )

  # Missing predicted_class
  expect_error(
    plot_classified_landscapes(
      data.frame(
        landscape_id = 1:2,
        actual_class = c("sharp", "diffuse"),
        confidence = c(0.95, 0.65)
      ),
      landscapes
    ),
    "Invalid classification results"
  )

  # Missing confidence
  expect_error(
    plot_classified_landscapes(
      data.frame(
        landscape_id = 1:2,
        actual_class = c("sharp", "diffuse"),
        predicted_class = c("sharp", "sharp")
      ),
      landscapes
    ),
    "Invalid classification results"
  )

  # Completely empty data frame
  expect_error(
    plot_classified_landscapes(data.frame(), landscapes),
    "Invalid classification results"
  )
})

test_that("plot_classified_landscapes rejects non-list landscapes", {
  classification <- data.frame(
    landscape_id = 1:2,
    actual_class = c("sharp", "diffuse"),
    predicted_class = c("sharp", "sharp"),
    confidence = c(0.95, 0.65)
  )

  expect_error(
    plot_classified_landscapes(classification, "not a list"),
    "landscapes must be a list"
  )

  expect_error(
    plot_classified_landscapes(classification, NULL),
    "landscapes must be a list"
  )

  expect_error(
    plot_classified_landscapes(
      classification,
      create_landscape("sharp", width = 20, height = 20)
    ),
    "landscapes must be a list"
  )
})

test_that("plot_classified_landscapes rejects empty landscapes list", {
  classification <- data.frame(
    landscape_id = 1:2,
    actual_class = c("sharp", "diffuse"),
    predicted_class = c("sharp", "sharp"),
    confidence = c(0.95, 0.65)
  )

  expect_error(
    plot_classified_landscapes(classification, list()),
    "landscapes must contain at least one landscape to plot"
  )
})

test_that("plot_classified_landscapes rejects invalid landscape objects", {
  classification <- data.frame(
    landscape_id = 1:3,
    actual_class = c("sharp", "diffuse", "random"),
    predicted_class = c("sharp", "sharp", "random"),
    confidence = c(0.95, 0.65, 0.80)
  )

  # Single invalid element at position 2
  invalid_list <- list(
    create_landscape("sharp", width = 20, height = 20),
    "not a landscape",
    create_landscape("random", width = 20, height = 20)
  )

  expect_error(
    plot_classified_landscapes(classification, invalid_list),
    ".*Found 1 invalid element at index.*2"
  )

  # Multiple invalid elements
  invalid_list2 <- list(
    "not a landscape",
    create_landscape("diffuse", width = 20, height = 20),
    42
  )

  expect_error(
    plot_classified_landscapes(classification, invalid_list2),
    ".*Found 2 invalid elements at indices.*"
  )

  # All invalid
  expect_error(
    plot_classified_landscapes(
      classification,
      list("a", "b", "c")
    ),
    ".*Found 3 invalid elements at indices.*"
  )
})

test_that("plot_classified_landscapes rejects length mismatch", {
  # More landscapes than classification rows
  landscapes_more <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("diffuse", width = 20, height = 20),
    create_landscape("random", width = 20, height = 20)
  )

  classification <- data.frame(
    landscape_id = 1:2,
    actual_class = c("sharp", "diffuse"),
    predicted_class = c("sharp", "sharp"),
    confidence = c(0.95, 0.65)
  )

  expect_warning(
    plot_classified_landscapes(classification, landscapes_more),
    "Length mismatch"
  )

  # Fewer landscapes than classification rows
  landscapes_fewer <- list(
    create_landscape("sharp", width = 20, height = 20)
  )

  classification2 <- data.frame(
    landscape_id = 1:2,
    actual_class = c("sharp", "diffuse"),
    predicted_class = c("sharp", "sharp"),
    confidence = c(0.95, 0.65)
  )

  expect_error(
    plot_classified_landscapes(classification2, landscapes_fewer),
    "Invalid landscape_id values detected"
  )
})

test_that("plot_classified_landscapes rejects invalid landscape_id values", {
  landscapes <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("diffuse", width = 20, height = 20),
    create_landscape("random", width = 20, height = 20)
  )

  # ID too low (0)
  classification_low <- data.frame(
    landscape_id = c(0, 1, 2),
    actual_class = c("sharp", "diffuse", "random"),
    predicted_class = c("sharp", "sharp", "random"),
    confidence = c(0.95, 0.65, 0.80)
  )

  expect_error(
    plot_classified_landscapes(classification_low, landscapes),
    "Invalid landscape_id"
  )

  # ID too high (4 > 3)
  classification_high <- data.frame(
    landscape_id = c(1, 2, 4),
    actual_class = c("sharp", "diffuse", "random"),
    predicted_class = c("sharp", "sharp", "random"),
    confidence = c(0.95, 0.65, 0.80)
  )

  expect_error(
    plot_classified_landscapes(classification_high, landscapes),
    "Invalid landscape_id"
  )

  # Multiple invalid IDs
  classification_both <- data.frame(
    landscape_id = c(0, 2, 5),
    actual_class = c("sharp", "diffuse", "random"),
    predicted_class = c("sharp", "sharp", "random"),
    confidence = c(0.95, 0.65, 0.80)
  )

  expect_error(
    plot_classified_landscapes(classification_both, landscapes),
    "Invalid landscape_id"
  )

  # Negative ID
  classification_negative <- data.frame(
    landscape_id = c(-1, 2, 3),
    actual_class = c("sharp", "diffuse", "random"),
    predicted_class = c("sharp", "sharp", "random"),
    confidence = c(0.95, 0.65, 0.80)
  )

  expect_error(
    plot_classified_landscapes(classification_negative, landscapes),
    "Invalid landscape_id"
  )
})

# Test plot_classified_landscapes filtering logic -----------------------

test_that("plot_classified_landscapes includes all landscapes by default", {
  landscapes <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("diffuse", width = 20, height = 20),
    create_landscape("random", width = 20, height = 20)
  )

  classification <- data.frame(
    landscape_id = 1:3,
    actual_class = c("sharp", "diffuse", "random"),
    predicted_class = c("sharp", "sharp", "random"), # One misclassified
    confidence = c(0.95, 0.65, 0.88)
  )

  result <- plot_classified_landscapes(classification, landscapes)
  expect_s3_class(result, "patchwork")
  # Should include all 3 landscapes
})

test_that("plot_classified_landscapes filters to misclassified only", {
  landscapes <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("diffuse", width = 20, height = 20),
    create_landscape("random", width = 20, height = 20)
  )

  classification <- data.frame(
    landscape_id = 1:3,
    actual_class = c("sharp", "diffuse", "random"),
    predicted_class = c("sharp", "sharp", "random"), # Only 2nd wrong
    confidence = c(0.95, 0.65, 0.88)
  )

  result <- plot_classified_landscapes(
    classification,
    landscapes,
    only_misclassified = TRUE
  )
  expect_s3_class(result, "patchwork")
  # Should only include 1 landscape (the misclassified one)
})

test_that("plot_classified_landscapes errors when no misclassifications", {
  landscapes <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("diffuse", width = 20, height = 20)
  )

  # All correct predictions
  classification <- data.frame(
    landscape_id = 1:2,
    actual_class = c("sharp", "diffuse"),
    predicted_class = c("sharp", "diffuse"),
    confidence = c(0.95, 0.88)
  )

  expect_error(
    plot_classified_landscapes(
      classification,
      landscapes,
      only_misclassified = TRUE
    ),
    "No misclassified landscapes found"
  )
})
