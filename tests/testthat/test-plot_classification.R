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
    score = c(0.95, 0.65)
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
        score = c(0.95, 0.65)
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
        score = c(0.95, 0.65)
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
        score = c(0.95, 0.65)
      ),
      landscapes
    ),
    "Invalid classification results"
  )

  # Missing score
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
    score = c(0.95, 0.65)
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
    score = c(0.95, 0.65)
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
    score = c(0.95, 0.65, 0.80)
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

test_that("plot_classified_landscapes titles unclassified landscapes", {
  landscapes <- create_fixture_landscapes("minimal")[1:2]

  classification <- tibble::tibble(
    landscape_id = 1:2,
    actual_class = c("spots", "labyrinth"),
    # apply_metric_model() returns NA when a landscape could not be classified
    predicted_class = c("spots", NA_character_),
    score = c(0.9, NA_real_)
  )

  result <- plot_classified_landscapes(
    classification = classification,
    landscapes = landscapes,
    only_misclassified = FALSE
  )
  expect_s3_class(result, "patchwork")

  titles <- vapply(
    seq_along(landscapes),
    function(i) result[[i]]$labels$title,
    character(1)
  )

  # The classified landscape keeps its normal title, the unclassified one is
  # labelled as such instead of falling through to "no title"
  expect_match(titles[1], "spots")
  expect_match(titles[2], "Unclassified")
  expect_match(titles[2], "Actual: labyrinth")
  expect_false(any(grepl("no title", titles)))
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
    score = c(0.95, 0.65)
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
    score = c(0.95, 0.65)
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
    score = c(0.95, 0.65, 0.80)
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
    score = c(0.95, 0.65, 0.80)
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
    score = c(0.95, 0.65, 0.80)
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
    score = c(0.95, 0.65, 0.80)
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
    score = c(0.95, 0.65, 0.88)
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
    score = c(0.95, 0.65, 0.88)
  )

  result <- plot_classified_landscapes(
    classification,
    landscapes,
    only_misclassified = TRUE
  )
  expect_s3_class(result, "patchwork")
  # Should only include 1 landscape (the misclassified one)
})

test_that("plot_classified_landscapes renders predicted-only titles for unlabeled input (H3)", {
  landscapes <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("diffuse", width = 20, height = 20)
  )

  # Unlabeled predictions: apply_*() always emit actual_class, which is NA (or
  # the "unclassified" sentinel) when the true class is unknown. Previously the
  # case_when() had no branch for this, so every title fell through to
  # "no title".
  classification <- data.frame(
    landscape_id = 1:2,
    actual_class = c(NA_character_, "unclassified"),
    predicted_class = c("sharp", "bands"),
    score = c(0.91, 0.55)
  )

  result <- plot_classified_landscapes(classification, landscapes)
  expect_s3_class(result, "patchwork")

  titles <- vapply(
    seq_along(landscapes),
    function(i) result[[i]]$labels$title,
    character(1)
  )
  # Predicted class is shown, with no "Actual:" line and no fallthrough title.
  expect_match(titles[1], "sharp")
  expect_match(titles[2], "bands")
  expect_false(any(grepl("no title", titles)))
  expect_false(any(grepl("Actual:", titles)))
})

test_that("plot_classified_landscapes returns a placeholder when nothing is misclassified", {
  landscapes <- list(
    create_landscape("sharp", width = 20, height = 20),
    create_landscape("diffuse", width = 20, height = 20)
  )

  # All correct predictions
  classification <- data.frame(
    landscape_id = 1:2,
    actual_class = c("sharp", "diffuse"),
    predicted_class = c("sharp", "diffuse"),
    score = c(0.95, 0.88)
  )

  # 100% accuracy is a legitimate outcome, so this must not abort - scripts
  # that always plot their misclassifications have to keep running.
  expect_message(
    result <- plot_classified_landscapes(
      classification,
      landscapes,
      only_misclassified = TRUE
    ),
    "All landscapes classified correctly"
  )

  # Still a patchwork, so printing and ggsave() work on the result
  expect_s3_class(result, "patchwork")
  expect_no_error(ggplot2::ggplot_build(result))
})
