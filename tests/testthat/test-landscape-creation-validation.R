# Input validation tests for landscape creation functions ---------------------

# Shared parameter validation -------------------------------------------------

# Width parameter validation --------------------------------------------------
test_that("landscape generators validate width parameter", {
  generators <- list(
    sharp = create_landscape_sharp_treeline,
    diffuse = create_landscape_diffuse_treeline,
    curvy = create_landscape_curvy_treeline,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered_trees,
    spots = create_landscape_spots
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(width = "50"),
      "must be a positive integer",
      info = paste("Testing", name, "with non-numeric width")
    )

    expect_error(
      gen(width = -10),
      "must be a positive integer",
      info = paste("Testing", name, "with negative width")
    )

    expect_error(
      gen(width = 0),
      "must be a positive integer",
      info = paste("Testing", name, "with zero width")
    )

    expect_error(
      gen(width = 10.5),
      "must be a positive integer",
      info = paste("Testing", name, "with non-integer width")
    )
  }
})

# Height parameter validation -------------------------------------------------
test_that("landscape generators validate height parameter", {
  generators <- list(
    sharp = create_landscape_sharp_treeline,
    diffuse = create_landscape_diffuse_treeline,
    curvy = create_landscape_curvy_treeline,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered_trees,
    spots = create_landscape_spots
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(height = "50"),
      "must be a positive integer",
      info = paste("Testing", name, "with non-numeric height")
    )

    expect_error(
      gen(height = -10),
      "must be a positive integer",
      info = paste("Testing", name, "with negative height")
    )

    expect_error(
      gen(height = 0),
      "must be a positive integer",
      info = paste("Testing", name, "with zero height")
    )

    expect_error(
      gen(height = 10.5),
      "must be a positive integer",
      info = paste("Testing", name, "with non-integer height")
    )
  }
})

# treeline_position parameter validation -------------------------------------------------
test_that("landscape generators validate treeline_position parameter", {
  generators <- list(
    sharp = create_landscape_sharp_treeline,
    diffuse = create_landscape_diffuse_treeline,
    curvy = create_landscape_curvy_treeline,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered_trees
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(treeline_position = "0.5"),
      "must be between 0 and 1.",
      info = paste("Testing", name, "with non-numeric treeline_position")
    )

    expect_error(
      gen(treeline_position = -0.1),
      "must be between 0 and 1.",
      info = paste("Testing", name, "with negative treeline_position")
    )

    expect_error(
      gen(treeline_position = 10.5),
      "must be between 0 and 1.",
      info = paste("Testing", name, "with treeline_position > 1")
    )
  }
})

# Rotation parameter validation -----------------------------------------------
test_that("landscape generators validate rotation parameter", {
  generators <- list(
    sharp = create_landscape_sharp_treeline,
    diffuse = create_landscape_diffuse_treeline,
    curvy = create_landscape_curvy_treeline,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered_trees,
    spots = create_landscape_spots
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(rotation = "45"),
      "must be numeric and between 0 and 360.",
      info = paste("Testing", name, "with non-numeric rotation")
    )

    expect_error(
      gen(rotation = -10),
      "must be numeric and between 0 and 360.",
      info = paste("Testing", name, "with negative rotation")
    )

    expect_error(
      gen(rotation = 400),
      "must be numeric and between 0 and 360.",
      info = paste("Testing", name, "with rotation > 360")
    )
  }
})

# Pattern-specific validation: random_spots parameter ------------------------
test_that("landscape generators validate random_spots parameter", {
  generators <- list(
    sharp = create_landscape_sharp_treeline,
    curvy = create_landscape_curvy_treeline,
    fingers = create_landscape_fingers,
    clustered = create_landscape_clustered_trees
  )

  for (name in names(generators)) {
    gen <- generators[[name]]

    expect_error(
      gen(random_spots = "invalid"),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with non-numeric random_spots")
    )

    expect_error(
      gen(random_spots = c(0.5)),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with length 1 random_spots")
    )

    expect_error(
      gen(random_spots = c(0.5, 0.5, 0.5)),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with length 3 random_spots")
    )

    expect_error(
      gen(random_spots = c(-0.1, 0.5)),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with negative value in random_spots")
    )

    expect_error(
      gen(random_spots = c(0.5, 1.5)),
      "must be a numeric vector of length 2",
      info = paste("Testing", name, "with value > 1 in random_spots")
    )
  }
})

# Pattern-specific validation: Diffuse treeline -------------------------------
test_that("diffuse treeline validates steepness parameter", {
  expect_error(
    create_landscape_diffuse_treeline(steepness = "2"),
    "must be numeric and between 0 and 1.",
    info = "Testing diffuse with non-numeric steepness"
  )

  expect_error(
    create_landscape_diffuse_treeline(steepness = -1),
    "must be numeric and between 0 and 1.",
    info = "Testing diffuse with negative steepness"
  )

  expect_error(
    create_landscape_diffuse_treeline(steepness = 2),
    "must be numeric and between 0 and 1.",
    info = "Testing diffuse with steepness > 1"
  )
})

# Pattern-specific validation: Curvy treeline ---------------------------------
test_that("curvy treeline validates sine_length parameter", {
  expect_error(
    create_landscape_curvy_treeline(sine_length = "20"),
    "must be a positive numeric value",
    info = "Testing curvy with non-numeric sine_length"
  )

  expect_error(
    create_landscape_curvy_treeline(sine_length = -10),
    "must be a positive numeric value",
    info = "Testing curvy with negative sine_length"
  )

  expect_error(
    create_landscape_curvy_treeline(sine_length = 0),
    "must be a positive numeric value",
    info = "Testing curvy with zero sine_length"
  )
})

test_that("curvy treeline validates sine_height parameter", {
  expect_error(
    create_landscape_curvy_treeline(sine_height = "5"),
    "must be a non-negative numeric value",
    info = "Testing curvy with non-numeric sine_height"
  )

  expect_error(
    create_landscape_curvy_treeline(sine_height = -5),
    "must be a non-negative numeric value",
    info = "Testing curvy with negative sine_height"
  )
})

# Pattern-specific validation: Curvy fingers treeline ------------------------
test_that("curvy fingers treeline validates sine_length_mean parameter", {
  expect_error(
    create_landscape_fingers(sine_length_mean = "20"),
    "must be a positive numeric value",
    info = "Testing fingers with non-numeric sine_length_mean"
  )

  expect_error(
    create_landscape_fingers(sine_length_mean = -10),
    "must be a positive numeric value",
    info = "Testing fingers with negative sine_length_mean"
  )

  expect_error(
    create_landscape_fingers(sine_length_mean = 0),
    "must be a positive numeric value",
    info = "Testing fingers with zero sine_length_mean"
  )
})

test_that("curvy fingers treeline validates sine_length_sd parameter", {
  expect_error(
    create_landscape_fingers(sine_length_sd = "5"),
    "must be a non-negative numeric value",
    info = "Testing fingers with non-numeric sine_length_sd"
  )

  expect_error(
    create_landscape_fingers(sine_length_sd = -5),
    "must be a non-negative numeric value",
    info = "Testing fingers with negative sine_length_sd"
  )
})

test_that("curvy fingers treeline validates sine_height_mean parameter", {
  expect_error(
    create_landscape_fingers(sine_height_mean = "5"),
    "must be a non-negative numeric value",
    info = "Testing fingers with non-numeric sine_height_mean"
  )

  expect_error(
    create_landscape_fingers(sine_height_mean = -5),
    "must be a non-negative numeric value",
    info = "Testing fingers with negative sine_height_mean"
  )
})

test_that("curvy fingers treeline validates sine_height_sd parameter", {
  expect_error(
    create_landscape_fingers(sine_height_sd = "3"),
    "must be a non-negative numeric value",
    info = "Testing fingers with non-numeric sine_height_sd"
  )

  expect_error(
    create_landscape_fingers(sine_height_sd = -3),
    "must be a non-negative numeric value",
    info = "Testing fingers with negative sine_height_sd"
  )
})

test_that("curvy fingers treeline warns about large sine_height_mean", {
  expect_warning(
    create_landscape_fingers(
      width = 20,
      height = 20,
      sine_height_mean = 15
    ),
    "large relative to",
    info = "Testing fingers with sine_height_mean > 50% of height"
  )
})

# Pattern-specific validation: Random -----------------------------------------
# Add random-specific parameter validation here when implemented

# Pattern-specific validation: Scattered trees --------------------------------
# Add scattered-specific parameter validation here when implemented

# Pattern-specific validation: Clustered trees --------------------------------
test_that("clustered trees validates n_clusters parameter", {
  expect_error(
    create_landscape_clustered_trees(n_clusters = -5),
    "must be a positive integer",
    info = "Testing clustered with negative n_clusters"
  )

  expect_error(
    create_landscape_clustered_trees(n_clusters = 0),
    "must be a positive integer",
    info = "Testing clustered with zero n_clusters"
  )
})

test_that("clustered trees validates cluster_radius parameter", {
  expect_error(
    create_landscape_clustered_trees(cluster_radius = "5"),
    "must be a positive number",
    info = "Testing clustered with non-numeric cluster_radius"
  )

  expect_error(
    create_landscape_clustered_trees(cluster_radius = -3),
    "must be a positive number",
    info = "Testing clustered with negative cluster_radius"
  )

  expect_error(
    create_landscape_clustered_trees(cluster_radius = 0),
    "must be a positive number",
    info = "Testing clustered with zero cluster_radius"
  )
})

test_that("clustered trees validates scatter_zone_prop parameter", {
  expect_error(
    create_landscape_clustered_trees(scatter_zone_prop = "0.3"),
    "must be between 0 and 1",
    info = "Testing clustered with non-numeric scatter_zone_prop"
  )

  expect_error(
    create_landscape_clustered_trees(scatter_zone_prop = -0.1),
    "must be between 0 and 1",
    info = "Testing clustered with negative scatter_zone_prop"
  )

  expect_error(
    create_landscape_clustered_trees(scatter_zone_prop = 0),
    "must be between 0 and 1",
    info = "Testing clustered with zero scatter_zone_prop"
  )

  expect_error(
    create_landscape_clustered_trees(scatter_zone_prop = 1.5),
    "must be between 0 and 1",
    info = "Testing clustered with scatter_zone_prop > 1"
  )
})

test_that("clustered trees validates elongation_x parameter", {
  expect_error(
    create_landscape_clustered_trees(elongation_x = "1.5"),
    "must be a positive number",
    info = "Testing clustered with non-numeric elongation_x"
  )

  expect_error(
    create_landscape_clustered_trees(elongation_x = -2),
    "must be a positive number",
    info = "Testing clustered with negative elongation_x"
  )

  expect_error(
    create_landscape_clustered_trees(elongation_x = 0),
    "must be a positive number",
    info = "Testing clustered with zero elongation_x"
  )
})

test_that("clustered trees validates elongation_y parameter", {
  expect_error(
    create_landscape_clustered_trees(elongation_y = "1.5"),
    "must be a positive number",
    info = "Testing clustered with non-numeric elongation_y"
  )

  expect_error(
    create_landscape_clustered_trees(elongation_y = -2),
    "must be a positive number",
    info = "Testing clustered with negative elongation_y"
  )

  expect_error(
    create_landscape_clustered_trees(elongation_y = 0),
    "must be a positive number",
    info = "Testing clustered with zero elongation_y"
  )
})

# Pattern-specific validation: Spots ------------------------------------------
test_that("spots validates n_spots parameter", {
  expect_error(
    create_landscape_spots(n_spots = -5),
    "must be a positive integer",
    info = "Testing spots with negative n_spots"
  )

  expect_error(
    create_landscape_spots(n_spots = 0),
    "must be a positive integer",
    info = "Testing spots with zero n_spots"
  )
})

test_that("spots validates spot_radius parameter", {
  expect_error(
    create_landscape_spots(spot_radius = "5"),
    "must be a positive number",
    info = "Testing spots with non-numeric spot_radius"
  )

  expect_error(
    create_landscape_spots(spot_radius = -3),
    "must be a positive number",
    info = "Testing spots with negative spot_radius"
  )

  expect_error(
    create_landscape_spots(spot_radius = 0),
    "must be a positive number",
    info = "Testing spots with zero spot_radius"
  )

  expect_error(
    create_landscape_spots(width = 100, height = 100, spot_radius = 60),
    "too large for the landscape dimensions",
    info = "Testing spots with spot_radius >= min(width, height) / 2"
  )
})

test_that("spots validates spot_radius_sd parameter", {
  expect_error(
    create_landscape_spots(spot_radius_sd = "2"),
    "must be a non-negative number",
    info = "Testing spots with non-numeric spot_radius_sd"
  )

  expect_error(
    create_landscape_spots(spot_radius_sd = -1),
    "must be a non-negative number",
    info = "Testing spots with negative spot_radius_sd"
  )
})

test_that("spots validates radius_noise_fraction parameter", {
  expect_error(
    create_landscape_spots(radius_noise_fraction = "0.5"),
    "must be between 0 and 1",
    info = "Testing spots with non-numeric radius_noise_fraction"
  )

  expect_error(
    create_landscape_spots(radius_noise_fraction = -0.1),
    "must be between 0 and 1",
    info = "Testing spots with negative radius_noise_fraction"
  )

  expect_error(
    create_landscape_spots(radius_noise_fraction = 1.5),
    "must be between 0 and 1",
    info = "Testing spots with radius_noise_fraction > 1"
  )
})

test_that("spots validates invert_landscape parameter", {
  expect_error(
    create_landscape_spots(invert_landscape = "TRUE"),
    "must be a single logical value",
    info = "Testing spots with non-logical invert_landscape"
  )

  expect_error(
    create_landscape_spots(invert_landscape = c(TRUE, FALSE)),
    "must be a single logical value",
    info = "Testing spots with vector invert_landscape"
  )
})

test_that("spots validates regular_spots parameter", {
  expect_error(
    create_landscape_spots(regular_spots = "TRUE"),
    "must be a single logical value",
    info = "Testing spots with non-logical regular_spots"
  )

  expect_error(
    create_landscape_spots(regular_spots = c(TRUE, FALSE)),
    "must be a single logical value",
    info = "Testing spots with vector regular_spots"
  )
})

test_that("spots warns when n_spots exceeds grid capacity for regular placement", {
  expect_warning(
    create_landscape_spots(
      width = 50,
      height = 50,
      n_spots = 100,
      spot_radius = 10,
      regular_spots = TRUE
    ),
    "only ~.* positions fit",
    info = "Testing spots with too many spots for regular placement"
  )
})
