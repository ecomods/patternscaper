#' Save a Trained Pixel Model
#'
#' Saves a complete pixel classifier as one model-bundle directory. The bundle
#' contains the trained Keras network and the R metadata needed by
#' \code{\link{apply_pixel_model}}, including class names, input dimensions, and
#' the fitted land-cover codes. Move or archive the complete folder rather than
#' the single files inside it.
#'
#' @param nn_model List. Trained pixel model returned by
#'   \code{\link{train_pixel_model}}.
#' @param path Character. Directory in which to save the complete model bundle.
#'   The path must not end in \file{.keras} or \file{.rds}; those files are
#'   managed inside the directory.
#' @param overwrite Logical. Whether to replace the model files in an existing
#'   directory (default: FALSE). Other files in that directory are not removed.
#'
#' @return The normalized bundle path, invisibly.
#' @seealso \code{\link{load_pixel_model}}, \code{\link{train_pixel_model}}
#' @family neural network training
#' @export
#' @examplesIf keras_available()
#' training_landscapes <- create_landscapes(
#'   n = 6,
#'   patterns = c("sharp", "random"),
#'   width = 20,
#'   height = 20
#' )
#' set_random_seed(42)
#' model <- train_pixel_model(
#'   training_landscapes,
#'   cv_method = "none",
#'   epochs = 1,
#'   verbose = FALSE
#' )
#'
#' model_bundle <- tempfile("pixel-model-")
#' save_pixel_model(model, model_bundle)
#' reloaded_model <- load_pixel_model(model_bundle)
#' # Clean up the temporary bundle created for this example.
#' unlink(model_bundle, recursive = TRUE)
save_pixel_model <- function(nn_model, path, overwrite = FALSE) {
  path <- validate_pixel_model_bundle_path(path)
  validate_pixel_model_overwrite(overwrite)
  validate_pixel_model_wrapper(nn_model)

  if (file.exists(path) && !dir.exists(path)) {
    cli::cli_abort(c(
      "Cannot save the pixel model bundle to {.path {path}}.",
      "x" = "That path is an existing file, not a directory."
    ))
  }

  if (dir.exists(path) && !overwrite) {
    cli::cli_abort(c(
      "Pixel model bundle already exists at {.path {path}}.",
      "i" = "Set {.arg overwrite} to {.code TRUE} to replace its model files."
    ))
  }

  if (!dir.exists(path)) {
    created <- suppressWarnings(dir.create(path, recursive = TRUE))
    if (!created && !dir.exists(path)) {
      cli::cli_abort(
        "Could not create pixel model bundle directory {.path {path}}."
      )
    }
  }

  bundle_paths <- pixel_model_bundle_paths(path)
  keras3::save_model(
    nn_model$model,
    bundle_paths$model,
    overwrite = overwrite
  )

  metadata <- nn_model
  metadata$model <- NULL
  # Version the bundle structure independently of the trained model.
  bundle_metadata <- list(
    format_version = 1L,
    metadata = metadata
  )
  saveRDS(bundle_metadata, bundle_paths$metadata, version = 3)

  invisible(normalizePath(path, winslash = "/", mustWork = TRUE))
}

#' Load a Trained Pixel Model
#'
#' Loads a model bundle written by \code{\link{save_pixel_model}} and
#' reconstructs the complete object expected by \code{\link{apply_pixel_model}}.
#'
#' @param path Character. Directory containing a saved pixel model bundle.
#'
#' @return A trained pixel model list with the Keras network and its R metadata.
#' @seealso \code{\link{save_pixel_model}}, \code{\link{apply_pixel_model}}
#' @family neural network application
#' @export
load_pixel_model <- function(path) {
  path <- validate_pixel_model_bundle_path(path)

  if (!dir.exists(path)) {
    detail <- if (file.exists(path)) {
      "The supplied path is a file, but a model-bundle directory is required."
    } else {
      "The model-bundle directory does not exist."
    }
    cli::cli_abort(c(
      "Cannot load pixel model bundle from {.path {path}}.",
      "x" = detail
    ))
  }

  bundle_paths <- pixel_model_bundle_paths(path)
  missing_files <- names(bundle_paths)[!file.exists(unlist(bundle_paths))]
  if (length(missing_files) > 0) {
    cli::cli_abort(c(
      "Pixel model bundle at {.path {path}} is incomplete.",
      "x" = "Missing bundle file{?s}: {.file {unname(unlist(bundle_paths[missing_files]))}}."
    ))
  }

  bundle_metadata <- tryCatch(
    readRDS(bundle_paths$metadata),
    error = function(cnd) {
      cli::cli_abort(
        "Could not read pixel model metadata from {.file {bundle_paths$metadata}}.",
        parent = cnd
      )
    }
  )
  validate_pixel_model_bundle_metadata(bundle_metadata, path)

  model <- keras3::load_model(bundle_paths$model)
  c(list(model = model), bundle_metadata$metadata)
}

validate_pixel_model_bundle_path <- function(path) {
  if (
    !is.character(path) ||
      length(path) != 1 ||
      is.na(path) ||
      !nzchar(path)
  ) {
    cli::cli_abort("{.arg path} must be a single non-empty character string.")
  }

  if (grepl("\\.(keras|rds)$", path, ignore.case = TRUE)) {
    cli::cli_abort(c(
      "{.arg path} must name a pixel model bundle directory.",
      "i" = "Do not add a {.file .keras} or {.file .rds} extension."
    ))
  }

  path.expand(path)
}

validate_pixel_model_overwrite <- function(overwrite) {
  if (
    !is.logical(overwrite) ||
      length(overwrite) != 1 ||
      is.na(overwrite)
  ) {
    cli::cli_abort("{.arg overwrite} must be a single logical value.")
  }
}

validate_pixel_model_wrapper <- function(nn_model) {
  required <- c("model", "classes", "input_shape", "land_cover_values")
  if (
    !is.list(nn_model) ||
      !all(required %in% names(nn_model)) ||
      is.null(nn_model$model)
  ) {
    cli::cli_abort(
      "{.arg nn_model} must be a trained model from {.fn train_pixel_model}."
    )
  }
}

pixel_model_bundle_paths <- function(path) {
  list(
    model = file.path(path, "model.keras"),
    metadata = file.path(path, "metadata.rds")
  )
}

validate_pixel_model_bundle_metadata <- function(bundle_metadata, path) {
  if (!is.list(bundle_metadata) || is.null(bundle_metadata$format_version)) {
    cli::cli_abort(
      "Pixel model bundle at {.path {path}} has invalid metadata."
    )
  }

  version <- bundle_metadata$format_version
  if (
    !is.numeric(version) ||
      length(version) != 1 ||
      is.na(version) ||
      version != 1L
  ) {
    version_label <- if (length(version) == 1 && !is.na(version)) {
      as.character(version)
    } else {
      "invalid"
    }
    cli::cli_abort(c(
      "Unsupported pixel model bundle format: {version_label}.",
      "i" = "This package version supports format 1."
    ))
  }

  metadata <- bundle_metadata$metadata
  required <- c("classes", "input_shape", "land_cover_values")
  if (!is.list(metadata) || !all(required %in% names(metadata))) {
    cli::cli_abort(
      "Pixel model bundle at {.path {path}} has invalid model metadata."
    )
  }
}
