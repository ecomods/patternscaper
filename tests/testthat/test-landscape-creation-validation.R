# Input validation tests for landscape creation functions ---------------------

# Shared parameter validation -------------------------------------------------

# Width parameter validation --------------------------------------------------
test_that("landscape generators validate width parameter", {
  generators <- list(
    sharp = create_landscape_sharp_treeline
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
    sharp = create_landscape_sharp_treeline
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
    sharp = create_landscape_sharp_treeline
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
    sharp = create_landscape_sharp_treeline
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
    sharp = create_landscape_sharp_treeline
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
# Add diffuse-specific parameter validation here when implemented

# Pattern-specific validation: Curvy treeline ---------------------------------
# Add curvy-specific parameter validation here when implemented

# Pattern-specific validation: Random -----------------------------------------
# Add random-specific parameter validation here when implemented

# Pattern-specific validation: Scattered trees --------------------------------
# Add scattered-specific parameter validation here when implemented

# Pattern-specific validation: Clustered trees --------------------------------
# Add clustered-specific parameter validation here when implemented

# Pattern-specific validation: Other patterns ---------------------------------
# Add validation tests for remaining patterns as they are implemented
