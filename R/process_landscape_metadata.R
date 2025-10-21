#' Add Metadata to Landscape
#'
#' Adds metadata to an existing landscape SpatRaster or matrix. This function creates
#' or updates the standard metadata structure used throughout the package. This
#' metadata structure preserves information about the landscape type and parameters
#' used to generate it, making the data more self-documenting and easier to process.
#'
#' @param landscape SpatRaster or matrix. Landscape to add metadata to.
#' @param type Character. Type of landscape pattern (e.g., "sharp", "diffuse", "clustered").
#' @param params List. Parameters used to create the landscape (e.g., width, height, density).
#'
#' @return List with landscape, type, and params components.
#' @export
add_landscape_metadata <- function(landscape, type = NA, params = list()) {
  # Check if input already has metadata structure (to avoid nesting)
  if (is.list(landscape) && !is.null(landscape$landscape)) {
    # Update existing metadata while preserving original structure
    warning("Input already has metadata structure. Updating metadata.")
    result <- landscape

    # Only update non-default values
    if (!is.na(type)) {
      result$type <- type
    }
    if (length(params) > 0) {
      result$params <- params
    }

    return(result)
  }

  # Create new metadata structure with standardized format
  return(list(
    landscape = landscape, # The actual raster or matrix data
    type = type, # Pattern type identifier
    params = params # Parameters used to generate
  ))
}

#' Check if Landscape has Metadata
#'
#' Checks if a landscape object includes metadata. This function is used
#' throughout the package to determine if objects need metadata extraction
#' or can be processed directly. The metadata structure is a list with at
#' minimum a 'landscape' component containing either a matrix or SpatRaster.
#'
#' @param x Object to check.
#'
#' @return Logical. TRUE if the object has metadata structure.
has_landscape_metadata <- function(x) {
  # Check three conditions:
  # 1. It must be a list
  # 2. It must have a 'landscape' component
  # 3. That component must be either a matrix or SpatRaster
  return(
    is.list(x) &&
      !is.null(x$landscape) &&
      (is.matrix(x$landscape) || inherits(x$landscape, "SpatRaster"))
  )
}

#' Get Landscape from Object
#'
#' Extracts the landscape raster or matrix from an object, handling both
#' simple SpatRaster/matrix objects and those with metadata structure.
#' This is useful for functions that need to work with just the landscape
#' data regardless of how it was stored.
#'
#' @param x Object containing landscape (SpatRaster, matrix, or list with metadata).
#'
#' @return SpatRaster or matrix containing the landscape data.
get_landscape <- function(x) {
  # If it has metadata structure, extract the landscape component
  if (has_landscape_metadata(x)) {
    return(x$landscape)
  } else {
    # Otherwise assume the whole object is the landscape
    return(x)
  }
}

#' Extract Landscape Type
#'
#' Gets the landscape type from metadata or returns NA if not available.
#' This function safely extracts the type information even if the object
#' doesn't have metadata, making it convenient to use in various contexts.
#'
#' @param x Landscape object (with or without metadata).
#'
#' @return Character string of landscape type or NA.
get_landscape_type <- function(x) {
  # If it has metadata structure, extract the type component
  if (has_landscape_metadata(x)) {
    return(x$type)
  } else {
    # No metadata, return NA to indicate unknown type
    return(NA)
  }
}

#' Extract Landscape Parameters
#'
#' Gets the landscape parameters from metadata or returns empty list if not available.
#' This function safely extracts the parameters information even if the object
#' doesn't have metadata, making it convenient to use in various contexts.
#'
#' @param x Landscape object (with or without metadata).
#'
#' @return List of landscape parameters or empty list.
get_landscape_params <- function(x) {
  # If it has metadata structure, extract the params component
  if (has_landscape_metadata(x)) {
    return(x$params)
  } else {
    # No metadata, return empty list to indicate no parameters
    return(list())
  }
}

#' Update Landscape with Enhanced Metadata Support
#'
#' This function enhances the ensure_spatraster function to properly handle landscape
#' metadata structures. It provides flexibility for working with both simple rasters and
#' metadata-enriched landscape objects, allowing functions that require raw SpatRaster
#' objects to work seamlessly with the new metadata format.
#'
#' @param landscape Object. Either SpatRaster, matrix, or list with landscape metadata.
#' @param extract_from_metadata Logical. Whether to extract just the SpatRaster (TRUE) or return the full metadata structure (FALSE).
#' @param silent Logical. Whether to suppress conversion message (default: TRUE).
#' @param crs Character. CRS to use if converting from matrix (default: NULL).
#'
#' @return List with landscape (SpatRaster or Matrix) and metadata or only landscape without metadata).
ensure_spatraster <- function(
  landscape,
  extract_from_metadata = TRUE,
  silent = TRUE,
  crs = NULL
) {
  # First, check if input has the metadata structure (list with landscape component)
  if (has_landscape_metadata(landscape)) {
    # Case 1: Input has metadata structure
    if (extract_from_metadata) {
      # Option 1A: Extract just the SpatRaster from metadata
      # This is useful when passing to functions that only work with raw SpatRaster objects
      if (inherits(landscape$landscape, "SpatRaster")) {
        # Already a SpatRaster, just extract it
        return(landscape$landscape)
      } else if (is.matrix(landscape$landscape)) {
        # Convert matrix to SpatRaster before returning
        if (!silent) {
          message("Converting matrix to SpatRaster...")
        }
        return(matrix_to_raster(landscape$landscape, crs = crs))
      }
    } else {
      # Option 1B: Keep metadata structure but ensure landscape component is a SpatRaster
      # This preserves type and parameter information while standardizing the format
      if (is.matrix(landscape$landscape)) {
        # Convert just the landscape component to SpatRaster
        if (!silent) {
          message("Converting matrix to SpatRaster...")
        }
        landscape$landscape <- matrix_to_raster(landscape$landscape, crs = crs)
      }
      # Return the entire metadata structure with standardized landscape component
      return(landscape)
    }
  } else if (is.matrix(landscape)) {
    # Case 2: Input is a plain matrix (no metadata)
    # Convert to SpatRaster for consistency
    if (!silent) {
      message("Converting matrix to SpatRaster...")
    }
    return(matrix_to_raster(landscape, crs = crs))
  } else if (inherits(landscape, "SpatRaster")) {
    # Case 3: Input is already a SpatRaster (no metadata)
    # Pass through unchanged
    return(landscape)
  } else {
    # Case 4: Input is invalid type
    # Provide clear error message about acceptable formats
    stop(
      "Input must be either a matrix, SpatRaster object, or list with landscape component"
    )
  }
}
