# Simple matrices of different patterns

# Create a uniform matrix of size n x n with all values equal to 'value'
# optionally add x % NA values in random locations
create_uniform_matrix <- function(n = 10, value = 1, na_percent = 0) {
  x <- matrix(value, nrow = n, ncol = n)
  if (na_percent > 0) {
    return(.introduce_nas(x, na_percent))
  }
  return(x)
}

# Create a gradient matrix of size n x n
# optionally remove values to introduce NAs
create_gradient_matrix <- function(n = 10, na_percent = 0) {
  x <- matrix(0, nrow = n, ncol = n)
  for (i in 1:n) {
    for (j in 1:n) {
      x[i, j] <- i + j
    }
  }
  if (na_percent > 0) {
    return(.introduce_nas(x, na_percent))
  }
  return(x)
}

# Create a random matrix of size n x n with values between 0 and 1
# optionally introduce NAs
create_random_matrix <- function(n = 10, seed = 123, na_percent = 0) {
  set.seed(seed)
  x <- matrix(runif(n * n), nrow = n, ncol = n)
  if (na_percent > 0) {
    return(.introduce_nas(x, na_percent))
  }
  return(x)
}

# Standard landscape objects
create_test_landscape <- function(
  type = "uniform",
  n = 10,
  na_percent = 0,
  class = NA_character_,
  name = NA_character_,
  params = NULL
) {
  mat <- switch(
    type,
    "uniform" = create_uniform_matrix(n, na_percent = na_percent),
    "gradient" = create_gradient_matrix(n, na_percent = na_percent),
    "random" = create_random_matrix(n, na_percent = na_percent),
    create_uniform_matrix(n, na_percent = na_percent)
  )
  landscape(mat, class = class, name = name, params = params)
}

# function to introduce random NAs into a matrix
.introduce_nas <- function(mat, na_percent) {
  if (na_percent < 0 || na_percent > 100) {
    stop("na_percent must be between 0 and 100")
  }
  total_elements <- length(mat)
  na_count <- ceiling(total_elements * na_percent / 100)
  na_indices <- sample(1:total_elements, na_count)
  mat[na_indices] <- NA
  return(mat)
}
