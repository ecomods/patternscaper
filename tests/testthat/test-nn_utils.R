# project_simplex / project_simplex_rows -------------------------------------

test_that("project_simplex returns a distribution for every kind of row", {
  rows <- list(
    ideal = c(1, 0, 0, 0, 0, 0),
    ambiguous = c(0.5, 0.5, 0, 0, 0, 0),
    mixed_sign = c(0.9, 0.3, -0.2, -0.4, 0.05, -0.1),
    all_negative = c(-0.1, -0.5, -0.2, -0.8, -0.3, -0.4),
    all_equal = rep(0.25, 6),
    above_one = c(1.4, 0.2, -0.3, 0.1, 0.0, -0.6),
    two_classes = c(0.8, 0.1)
  )

  for (label in names(rows)) {
    p <- project_simplex(rows[[label]])
    expect_equal(sum(p), 1, tolerance = 1e-12, info = label)
    expect_true(all(p >= 0), info = label)
    expect_length(p, length(rows[[label]]))
  }
})

test_that("project_simplex leaves an existing distribution unchanged", {
  v <- c(0.5, 0.2, 0.15, 0.1, 0.05, 0)
  expect_equal(project_simplex(v), v)
})

test_that("project_simplex preserves the argmax", {
  # The reporting transform must never move a class boundary, otherwise the
  # reported accuracy would depend on it.
  set.seed(42)
  for (i in 1:200) {
    v <- rnorm(6, mean = runif(1, -1, 1), sd = runif(1, 0.05, 2))
    expect_equal(which.max(project_simplex(v)), which.max(v))
  }
})

test_that("project_simplex preserves differences but not ratios", {
  # Two rows with the same top-two gap but very different top-two ratios
  # project to the same point: gaps carry information, ratios do not.
  a <- project_simplex(c(0.4, 0.1, 0, 0, 0, 0))
  b <- project_simplex(c(0.9, 0.6, 0.5, 0.5, 0.5, 0.5))

  expect_equal(a, b)
  expect_equal(a[1] - a[2], 0.3)
})

test_that("project_simplex handles a fully undecided row", {
  p <- project_simplex(rep(0, 6))
  expect_equal(p, rep(1 / 6, 6))
})

test_that("project_simplex propagates non-finite values rather than dropping them", {
  # sort() silently drops NA, and an Inf makes the running total infinite and
  # the threshold test NaN. Either would pick the wrong active set in silence.
  expect_true(all(is.na(project_simplex(c(0.5, NA, 0.2)))))
  expect_true(all(is.na(project_simplex(c(0.5, NaN, 0.2)))))
  expect_true(all(is.na(project_simplex(c(0.5, Inf, 0.2)))))
  expect_true(all(is.na(project_simplex(c(0.5, -Inf, 0.2)))))
})

test_that("project_simplex handles empty input", {
  expect_equal(project_simplex(numeric(0)), numeric(0))
})

test_that("project_simplex only preserves gaps between classes that keep mass", {
  # Gaps among the surviving classes are unchanged, because they all move by
  # the same shift. A class pushed to exactly 0 loses that guarantee -- the
  # projection discards how far below the others it was.
  v <- c(0.6, 0.2, -0.8)
  p <- project_simplex(v)

  expect_equal(p[1] - p[2], v[1] - v[2]) # both keep mass: gap preserved
  expect_equal(p[3], 0)
  expect_false(isTRUE(all.equal(p[2] - p[3], v[2] - v[3]))) # clipped: not preserved
})

test_that("project_simplex is stable on near-boundary rows", {
  # Rows engineered so a class sits essentially exactly on the activity
  # threshold, where floating-point noise could drop it from the active set.
  for (eps in c(0, 1e-16, -1e-16, 1e-12, -1e-12)) {
    v <- c(0.5, 0.5, -1 / 3 + eps)
    p <- project_simplex(v)
    expect_equal(sum(p), 1, tolerance = 1e-10)
    expect_true(all(p >= 0))
  }
})

test_that("project_simplex_rows keeps shape and dimnames", {
  x <- matrix(
    c(
      1, 0, 0,
      -0.2, -0.5, -0.1,
      0.4, 0.4, 0.2
    ),
    nrow = 3,
    byrow = TRUE,
    dimnames = list(NULL, c("bands", "random", "sharp"))
  )

  p <- project_simplex_rows(x)

  expect_equal(dim(p), dim(x))
  expect_equal(colnames(p), colnames(x))
  expect_equal(rowSums(p), rep(1, 3), tolerance = 1e-12)
  expect_true(all(p >= 0))
  expect_equal(max.col(p, ties.method = "first"), max.col(x, ties.method = "first"))
})

test_that("project_simplex_rows does not compress the scores the way softmax did", {
  # Regression test for the bug this replaced: softmax on outputs that already
  # sit near 0/1 capped the maximum at e / (e + k - 1) = 0.35 for six classes,
  # even for a perfect prediction.
  perfect <- matrix(c(1, 0, 0, 0, 0, 0), nrow = 1)

  expect_equal(max(project_simplex_rows(perfect)), 1)

  softmax_max <- exp(1) / (exp(1) + 5)
  expect_gt(max(project_simplex_rows(perfect)), softmax_max)
})

test_that("project_simplex_rows works for a single row and a single class", {
  one_row <- project_simplex_rows(matrix(c(0.7, 0.2, -0.1), nrow = 1))
  expect_equal(dim(one_row), c(1L, 3L))
  expect_equal(sum(one_row), 1)

  one_class <- project_simplex_rows(matrix(c(0.3, -2), ncol = 1))
  expect_equal(dim(one_class), c(2L, 1L))
  expect_equal(as.vector(one_class), c(1, 1))
})

test_that("project_simplex_rows handles a zero-row matrix", {
  empty <- project_simplex_rows(matrix(numeric(0), nrow = 0, ncol = 3))
  expect_equal(dim(empty), c(0L, 3L))
})

test_that("project_simplex_rows isolates a non-finite row", {
  # One bad row must not contaminate the others
  x <- matrix(c(1, 0, 0, Inf, 0, 0, 0.5, 0.3, 0.2), nrow = 3, byrow = TRUE)
  p <- project_simplex_rows(x)

  expect_true(all(is.na(p[2, ])))
  expect_equal(rowSums(p[c(1, 3), ]), c(1, 1))
})

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
      "score"
    ) %in%
      names(result$validation_results)
  ))

  # Check scores lie in [0, 1] (a valid distribution, not a calibrated one)
  expect_true(all(result$validation_results$score >= 0))
  expect_true(all(result$validation_results$score <= 1))

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
  expect_true(all(result$per_class_metrics$recall == 1.0))
  expect_true(all(result$per_class_metrics$precision == 1.0))
  expect_true(all(result$per_class_metrics$f1_score == 1.0))
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
  expect_true(all(result$per_class_metrics$f1_score == 0.0))
})

test_that("evaluate_cv_performance reports a class absent from the evaluation data as NA, not 0", {
  # Model knows "A", "B" and "C", but "C" never occurs in the evaluation data.
  # "B" occurs but is always misclassified as "A" - a real failure, distinct
  # from "C" which was never evaluated at all.
  cv_predictions <- list(c("A", "A"))

  cv_probabilities <- list(
    matrix(
      c(0.8, 0.1, 0.1, 0.7, 0.2, 0.1),
      nrow = 2,
      byrow = TRUE,
      dimnames = list(NULL, c("A", "B", "C"))
    )
  )

  # A plain character vector, as apply_metric_model() produces (not a factor
  # with class_names as levels) - table() then has no zero-count entry for
  # "C" at all, which is what makes indexing by class_names below yield NA.
  cv_actual <- list(c("A", "B"))
  cv_landscape_ids <- list(c(1, 2))

  warnings <- capture_warnings(
    result <- evaluate_cv_performance(
      cv_predictions = cv_predictions,
      cv_probabilities = cv_probabilities,
      cv_actual = cv_actual,
      cv_landscape_ids = cv_landscape_ids,
      class_names = c("A", "B", "C"),
      cv_method = "k-fold",
      cv_folds = 1,
      verbose = FALSE
    )
  )

  # Warned about the genuinely-failed class and the absent class separately
  expect_true(any(grepl("never correctly predicted.*\"B\"", warnings)))
  expect_true(any(grepl("do not occur in the evaluation data.*\"C\"", warnings)))
  # "C" is absent, not failed, so it must not appear in the failure warning
  expect_false(any(grepl("never correctly predicted.*\"C\"", warnings)))

  metrics_c <- dplyr::filter(result$per_class_metrics, class == "C")
  expect_true(is.na(metrics_c$count))
  expect_true(is.na(metrics_c$recall))
  expect_true(is.na(metrics_c$precision))
  expect_true(is.na(metrics_c$f1_score))
  expect_true(is.na(result$class_counts[3]))

  # "B" is present but always misclassified: a real 0, not NA
  metrics_b <- dplyr::filter(result$per_class_metrics, class == "B")
  expect_equal(metrics_b$count, 1)
  expect_equal(unname(metrics_b$recall), 0)
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

# scale_fold ------------------------------------------------------------------
# Guards against the CV feature-scaling leakage fixed in M1: the validation fold
# must be scaled using the training fold's center/scale only, never its own.

test_that("scale_fold scales the validation fold with training-fold statistics only", {
  train <- data.frame(a = c(1, 2, 3, 4), b = c(10, 20, 30, 40))
  val <- data.frame(a = c(5, 6), b = c(50, 60))

  res <- scale_fold(train, val)

  center <- colMeans(train)
  scale_sd <- vapply(train, stats::sd, numeric(1))

  # Validation is transformed by TRAINING stats, not recomputed on itself
  expect_equal(
    as.numeric(res$val[, "a"]),
    (val$a - center[["a"]]) / scale_sd[["a"]]
  )
  expect_equal(
    as.numeric(res$val[, "b"]),
    (val$b - center[["b"]]) / scale_sd[["b"]]
  )

  # Training fold is standardised: column means ~0, sds ~1
  expect_equal(colMeans(res$train), c(a = 0, b = 0), ignore_attr = TRUE)
  expect_equal(apply(res$train, 2, stats::sd), c(a = 1, b = 1), ignore_attr = TRUE)
})

test_that("scale_fold guards columns constant within the training fold (no NaN)", {
  # 'const' has zero variance in the training fold -> scale = 1, not a /0 -> NaN
  train <- data.frame(a = c(1, 2, 3), const = c(5, 5, 5))
  val <- data.frame(a = c(4), const = c(9))

  res <- scale_fold(train, val)

  expect_false(any(is.nan(res$train)))
  expect_false(any(is.nan(res$val)))
  # centered by the training mean (5), scaled by the guarded sd (1)
  expect_equal(as.numeric(res$val[, "const"]), 4)
  expect_equal(as.numeric(res$train[, "const"]), c(0, 0, 0))
})

test_that("scale_fold handles a single-row validation fold (LOO)", {
  train <- data.frame(a = c(1, 2, 3, 4), b = c(2, 4, 6, 8))
  val <- data.frame(a = 5, b = 10)

  res <- scale_fold(train, val)

  expect_equal(dim(res$val), c(1L, 2L))
  expect_false(any(is.nan(res$val)))
})

test_that("is_constant_sd catches floating-point noise, not real variation", {
  # Exactly constant, and constant up to floating-point summation error
  expect_true(is_constant_sd(0, 1))
  expect_true(is_constant_sd(1.17e-17, 1))
  # NA arises for a single observation - no usable variation either
  expect_true(is_constant_sd(NA_real_, 1))

  # Real variation is kept, on small and large scales alike
  expect_false(is_constant_sd(0.1, 1))
  expect_false(is_constant_sd(1e-6, 1e-6))

  # Tolerance is relative, so a large mean does not swallow real variation
  expect_false(is_constant_sd(5, 87.7))
  expect_true(is_constant_sd(1e-12, 1e4))

  expect_equal(
    is_constant_sd(c(0, 0.5), c(1, 1)),
    c(TRUE, FALSE)
  )
})

test_that("scaling_stats guards near-constant columns", {
  # 'noisy_const' is 1 everywhere but with floating-point wobble, which is
  # exactly what total area looks like across equally sized landscapes
  predictors <- data.frame(
    a = c(1, 2, 3, 4),
    noisy_const = c(1, 1, 1, 1 + 2e-16)
  )

  stats <- scaling_stats(predictors)

  expect_equal(stats$scale[["noisy_const"]], 1)
  expect_gt(stats$scale[["a"]], 1)

  scaled <- scale(predictors, center = stats$center, scale = stats$scale)
  expect_false(any(is.nan(scaled)))
  # Without the guard these would be z-scores of order 1e16
  expect_true(all(abs(scaled[, "noisy_const"]) < 1e-10))
})

test_that("fit_nn_model aborts when neuralnet fails to converge", {
  data <- data.frame(
    a = c(-1, 0, 1, 2, -2, 0.5),
    b = c(1, 0, -1, -2, 2, -0.5),
    pattern = factor(c("x", "y", "x", "y", "x", "y"))
  )

  # stepmax = 1 cannot converge; neuralnet only warns and returns an object
  # without weights, which must not be handed back as a usable model
  expect_error(
    suppressWarnings(
      fit_nn_model(data, hidden = 6, threshold = 0.01, stepmax = 1)
    ),
    "did not converge"
  )
})
