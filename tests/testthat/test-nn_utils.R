test_that("find_balanced_cv_folds creates stratified folds", {
  set.seed(123)
  patterns <- factor(c(rep("A", 10), rep("B", 10), rep("C", 10)))

  folds <- find_balanced_cv_folds(patterns, cv_folds = 5)

  # Each sample assigned to exactly one fold
  expect_length(folds, 30)
  expect_true(all(folds %in% 1:5))

  # Each class appears in multiple folds (stratification check)
  for (class in c("A", "B", "C")) {
    class_folds <- folds[patterns == class]
    expect_gt(length(unique(class_folds)), 1)
  }

  # Folds are roughly balanced
  fold_counts <- table(folds)
  expect_true(max(fold_counts) - min(fold_counts) <= 1)
})

test_that("find_balanced_cv_folds handles edge cases", {
  # Single class
  patterns <- factor(rep("A", 10))
  folds <- find_balanced_cv_folds(patterns, cv_folds = 3)
  expect_length(folds, 10)
  expect_equal(length(unique(folds)), 3)

  # More folds than samples in smallest class
  patterns <- factor(c(rep("A", 2), rep("B", 10)))
  folds <- find_balanced_cv_folds(patterns, cv_folds = 5)
  # Class A should still appear in 2 folds
  expect_equal(length(unique(folds[patterns == "A"])), 2)
})

test_that("evaluate_cv_performance calculates correct metrics", {
  # Setup test data with known outcomes
  cv_predictions <- list(
    c("A", "A", "B"),
    c("B", "C", "C")
  )

  cv_probabilities <- list(
    matrix(
      c(0.9, 0.05, 0.05, 0.8, 0.1, 0.1, 0.1, 0.8, 0.1),
      nrow = 3,
      byrow = TRUE,
      dimnames = list(NULL, c("A", "B", "C"))
    ),
    matrix(
      c(0.1, 0.85, 0.05, 0.05, 0.1, 0.85, 0.05, 0.05, 0.9),
      nrow = 3,
      byrow = TRUE,
      dimnames = list(NULL, c("A", "B", "C"))
    )
  )

  cv_actual <- list(
    factor(c("A", "A", "B"), levels = c("A", "B", "C")),
    factor(c("B", "C", "B"), levels = c("A", "B", "C"))
  )

  cv_landscape_ids <- list(c(1, 2, 3), c(4, 5, 6))

  class_names <- c("A", "B", "C")

  # Run evaluation
  result <- evaluate_cv_performance(
    cv_predictions = cv_predictions,
    cv_probabilities = cv_probabilities,
    cv_actual = cv_actual,
    cv_landscape_ids = cv_landscape_ids,
    class_names = class_names,
    cv_method = "k-fold",
    cv_folds = 2,
    verbose = FALSE
  )

  # Check overall accuracy (5 correct out of 6)
  expect_equal(result$accuracy, 5 / 6)

  # Check confusion matrix dimensions
  expect_equal(dim(result$confusion_matrix), c(3, 3))

  # Check per-class metrics structure
  expect_s3_class(result$per_class_metrics, "tbl_df")
  expect_named(
    result$per_class_metrics,
    c("class", "count", "recall", "precision", "f1_score")
  )
  expect_equal(nrow(result$per_class_metrics), 3)

  # Check validation results structure
  expect_s3_class(result$validation_results, "tbl_df")
  expect_equal(nrow(result$validation_results), 6)
  expect_true(all(
    c(
      "landscape_id",
      "fold",
      "actual_class",
      "predicted_class",
      "confidence"
    ) %in%
      names(result$validation_results)
  ))

  # Check confidence values are probabilities
  expect_true(all(result$validation_results$confidence >= 0))
  expect_true(all(result$validation_results$confidence <= 1))

  # Check fold assignments are correct
  expect_equal(result$validation_results$fold, c(1, 1, 1, 2, 2, 2))
})

test_that("evaluate_cv_performance handles perfect classification", {
  cv_predictions <- list(c("A", "B"), c("A", "B"))

  cv_probabilities <- list(
    matrix(
      c(1, 0, 0, 1),
      nrow = 2,
      byrow = TRUE,
      dimnames = list(NULL, c("A", "B"))
    ),
    matrix(
      c(1, 0, 0, 1),
      nrow = 2,
      byrow = TRUE,
      dimnames = list(NULL, c("A", "B"))
    )
  )

  cv_actual <- list(
    factor(c("A", "B"), levels = c("A", "B")),
    factor(c("A", "B"), levels = c("A", "B"))
  )

  cv_landscape_ids <- list(c(1, 2), c(3, 4))

  result <- evaluate_cv_performance(
    cv_predictions = cv_predictions,
    cv_probabilities = cv_probabilities,
    cv_actual = cv_actual,
    cv_landscape_ids = cv_landscape_ids,
    class_names = c("A", "B"),
    cv_method = "k-fold",
    cv_folds = 2,
    verbose = FALSE
  )

  # Perfect accuracy
  expect_equal(result$accuracy, 1.0)

  # All metrics should be 1.0
  expect_true(all(result$per_class_metrics$Recall == 1.0))
  expect_true(all(result$per_class_metrics$Precision == 1.0))
  expect_true(all(result$per_class_metrics$F1_Score == 1.0))
})

test_that("evaluate_cv_performance handles complete misclassification", {
  cv_predictions <- list(c("B", "A"))

  cv_probabilities <- list(
    matrix(
      c(0.1, 0.9, 0.9, 0.1),
      nrow = 2,
      byrow = TRUE,
      dimnames = list(NULL, c("A", "B"))
    )
  )

  cv_actual <- list(factor(c("A", "B"), levels = c("A", "B")))
  cv_landscape_ids <- list(c(1, 2))

  expect_warning(
    result <- evaluate_cv_performance(
      cv_predictions = cv_predictions,
      cv_probabilities = cv_probabilities,
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = c("A", "B"),
      cv_method = "k-fold",
      cv_folds = 1,
      verbose = FALSE
    ),
    "never correctly predicted"
  )

  # Zero accuracy
  expect_equal(result$accuracy, 0.0)

  # All metrics should be 0.0
  expect_true(all(result$per_class_metrics$recall == 0.0))
  expect_true(all(result$per_class_metrics$precision == 0.0))
  expect_true(all(result$per_class_metrics$f1_Score == 0.0))
})

test_that("evaluate_cv_performance validates input lengths", {
  cv_predictions <- list(c("A", "B"))
  cv_probabilities <- list(
    matrix(
      c(1, 0, 0, 1),
      nrow = 2,
      byrow = TRUE,
      dimnames = list(NULL, c("A", "B"))
    )
  )
  cv_actual <- list(factor(c("A", "B"), levels = c("A", "B")))
  cv_landscape_ids <- list(c(1, 2))

  # Mismatched cv_predictions and cv_actual lengths
  expect_error(
    evaluate_cv_performance(
      cv_predictions = list(c("A", "B"), c("A")), # 2 folds
      cv_probabilities = cv_probabilities, # 1 fold
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = c("A", "B"),
      cv_method = "k-fold",
      cv_folds = 2,
      verbose = FALSE
    ),
    "Length of"
  )
})

test_that("evaluate_cv_performance validates probability matrix format", {
  cv_predictions <- list(c("A", "B"))
  cv_actual <- list(factor(c("A", "B"), levels = c("A", "B")))
  cv_landscape_ids <- list(c(1, 2))

  # cv_probabilities not a matrix/data frame
  expect_error(
    evaluate_cv_performance(
      cv_predictions = cv_predictions,
      cv_probabilities = list(c(0.9, 0.1)), # vector instead of matrix
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = c("A", "B"),
      cv_method = "k-fold",
      cv_folds = 1,
      verbose = FALSE
    ),
    "must contain matrices or data frames"
  )
})

test_that("evaluate_cv_performance validates class names match", {
  cv_predictions <- list(c("A", "B"))
  cv_probabilities <- list(
    matrix(
      c(1, 0, 0, 1),
      nrow = 2,
      byrow = TRUE,
      dimnames = list(NULL, c("X", "Y"))
    ) # Wrong names
  )
  cv_actual <- list(factor(c("A", "B"), levels = c("A", "B")))
  cv_landscape_ids <- list(c(1, 2))

  expect_error(
    evaluate_cv_performance(
      cv_predictions = cv_predictions,
      cv_probabilities = cv_probabilities,
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = c("A", "B"),
      cv_method = "k-fold",
      cv_folds = 1,
      verbose = FALSE
    ),
    "column names don't match class_names"
  )
})

test_that("evaluate_cv_performance handles LOO correctly", {
  # For LOO, cv_folds should equal number of samples
  cv_predictions <- list("A", "B", "A")
  cv_probabilities <- list(
    matrix(c(0.9, 0.1), nrow = 1, dimnames = list(NULL, c("A", "B"))),
    matrix(c(0.1, 0.9), nrow = 1, dimnames = list(NULL, c("A", "B"))),
    matrix(c(0.8, 0.2), nrow = 1, dimnames = list(NULL, c("A", "B")))
  )
  cv_actual <- list(
    factor("A", levels = c("A", "B")),
    factor("B", levels = c("A", "B")),
    factor("A", levels = c("A", "B"))
  )
  cv_landscape_ids <- list(1, 2, 3)

  result <- evaluate_cv_performance(
    cv_predictions = cv_predictions,
    cv_probabilities = cv_probabilities,
    cv_actual = cv_actual,
    cv_landscape_ids = cv_landscape_ids,
    class_names = c("A", "B"),
    cv_method = "loo",
    cv_folds = 3,
    verbose = FALSE
  )

  # Check that each sample is in its own fold
  expect_equal(result$validation_results$fold, c(1, 2, 3))
  expect_equal(result$cv_method, "loo")
  expect_equal(result$cv_folds, 3)
})

# Tests for validate_cv_params() --------------------------------------------

test_that("validate_cv_params returns correct structure for cv_method = 'none'", {
  patterns <- factor(c(rep("A", 10), rep("B", 10), rep("C", 10)))

  result <- validate_cv_params(
    patterns = patterns,
    cv_method = "none",
    cv_folds = 5 # Should be ignored
  )

  expect_type(result, "list")
  expect_named(
    result,
    c("cv_method", "cv_folds", "class_counts", "total_samples")
  )
  expect_equal(result$cv_method, "none")
  expect_equal(result$cv_folds, 1L)
  expect_equal(result$total_samples, 30)
  expect_equal(as.vector(result$class_counts), c(10, 10, 10))
})

test_that("validate_cv_params maintains k-fold when dataset is adequate", {
  patterns <- factor(c(rep("A", 20), rep("B", 20), rep("C", 20)))

  result <- validate_cv_params(
    patterns = patterns,
    cv_method = "k-fold",
    cv_folds = 5
  )

  expect_equal(result$cv_method, "k-fold")
  expect_equal(result$cv_folds, 5)
})

test_that("validate_cv_params reduces cv_folds when necessary", {
  # With 15 samples per class and min_samples_per_fold = 3,
  # max_suitable_folds = floor(15/3) = 5
  patterns <- factor(c(rep("A", 15), rep("B", 15), rep("C", 15)))

  expect_message(
    result <- validate_cv_params(
      patterns = patterns,
      cv_method = "k-fold",
      cv_folds = 10, # Too many folds
      min_samples_per_fold = 3
    ),
    "Reducing CV folds from 10 to 5"
  )

  expect_equal(result$cv_method, "k-fold")
  expect_equal(result$cv_folds, 5)
})

test_that("validate_cv_params switches k-fold to LOO when needed", {
  # With 5 samples per class and min_samples_per_fold = 3,
  # max_suitable_folds = floor(5/3) = 1 < 2, so switch to LOO
  patterns <- factor(c(rep("A", 5), rep("B", 5), rep("C", 5)))

  expect_message(
    result <- validate_cv_params(
      patterns = patterns,
      cv_method = "k-fold",
      cv_folds = 5,
      min_samples_per_fold = 3
    ),
    "Switching to LOO CV"
  )

  expect_equal(result$cv_method, "loo")
  expect_equal(result$cv_folds, 15) # total_samples
})

test_that("validate_cv_params validates LOO requirements", {
  # LOO requires at least 2 samples per class
  patterns <- factor(c("A", rep("B", 10), rep("C", 10)))

  expect_error(
    validate_cv_params(
      patterns = patterns,
      cv_method = "loo",
      cv_folds = 21
    ),
    "Cannot perform LOO CV.*only 1 sample"
  )
})

test_that("validate_cv_params warns about computationally expensive LOO", {
  # Create dataset with > 100 samples
  patterns <- factor(rep(LETTERS[1:5], each = 25)) # 125 samples

  expect_message(
    result <- validate_cv_params(
      patterns = patterns,
      cv_method = "loo",
      cv_folds = 125
    ),
    "LOO CV with 125 samples may be slow"
  )

  expect_equal(result$cv_method, "loo")
  expect_equal(result$cv_folds, 125)
})

test_that("validate_cv_params detects low sample-to-predictor ratio", {
  patterns <- factor(c(rep("A", 10), rep("B", 10)))

  expect_message(
    validate_cv_params(
      patterns = patterns,
      cv_method = "k-fold",
      cv_folds = 5,
      n_predictors = 50 # 20 samples / 50 predictors = 0.4 < 5
    ),
    "Low sample-to-predictor ratio"
  )
})

test_that("validate_cv_params detects class imbalance", {
  # 10:1 imbalance ratio
  patterns <- factor(c(rep("A", 100), rep("B", 10)))

  expect_message(
    validate_cv_params(
      patterns = patterns,
      cv_method = "k-fold",
      cv_folds = 5
    ),
    "Severe class imbalance.*ratio 10:1"
  )
})

test_that("validate_cv_params warns about small classes", {
  patterns <- factor(c(rep("A", 2), rep("B", 20), rep("C", 20)))

  expect_message(
    result <- validate_cv_params(
      patterns = patterns,
      cv_method = "k-fold",
      cv_folds = 5,
      min_samples_per_fold = 3
    ),
    "Some classes have few samples.*A"
  )
})

test_that("validate_cv_params respects min_samples_per_fold parameter", {
  patterns <- factor(c(rep("A", 10), rep("B", 10)))

  # With min_samples_per_fold = 2, max_folds = 10/2 = 5
  result <- validate_cv_params(
    patterns = patterns,
    cv_method = "k-fold",
    cv_folds = 7,
    min_samples_per_fold = 2
  )

  expect_equal(result$cv_folds, 5)

  # With min_samples_per_fold = 5, max_folds = 10/5 = 2
  result <- validate_cv_params(
    patterns = patterns,
    cv_method = "k-fold",
    cv_folds = 7,
    min_samples_per_fold = 5
  )

  expect_equal(result$cv_folds, 2)
})

test_that("validate_cv_params sets cv_folds to total_samples for LOO", {
  patterns <- factor(c(rep("A", 15), rep("B", 15)))

  result <- validate_cv_params(
    patterns = patterns,
    cv_method = "loo",
    cv_folds = 30 # Should be maintained as total_samples
  )

  expect_equal(result$cv_method, "loo")
  expect_equal(result$cv_folds, 30)
})

test_that("validate_cv_params handles edge case with exactly min samples", {
  # Each class has exactly min_samples_per_fold * cv_folds samples
  patterns <- factor(c(rep("A", 15), rep("B", 15))) # 15 = 3 * 5

  result <- validate_cv_params(
    patterns = patterns,
    cv_method = "k-fold",
    cv_folds = 5,
    min_samples_per_fold = 3
  )

  # Should not reduce folds or switch methods
  expect_equal(result$cv_method, "k-fold")
  expect_equal(result$cv_folds, 5)
})

# set_random_seed tests --------------------------------------------------------

test_that("set_random_seed makes R random results reproducible", {
  set_random_seed(42)
  x1 <- runif(10)

  set_random_seed(42)
  x2 <- runif(10)

  expect_equal(x1, x2)
})

test_that("set_random_seed with different seeds gives different results", {
  set_random_seed(42)
  x1 <- runif(10)

  set_random_seed(99)
  x2 <- runif(10)

  expect_false(all(x1 == x2))
})
