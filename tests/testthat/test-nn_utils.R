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
