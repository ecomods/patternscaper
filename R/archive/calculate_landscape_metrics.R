
calculate_landscape_metrics <- function(all_patterns,types){

  # convert all landscapes to raster
  all_patterns_raster <- map(all_patterns, ~ terra::rast(.x))

  # list all landscape level metrics from landscapemetrics package
  all_l_functions <- landscapemetrics::list_lsm() |> filter(level == "landscape")
  # list all class functions
  all_c_functions <- landscapemetrics::list_lsm() |> filter(level == "class")

  # extract all function names (will be used in the next step to run them all)
  all_l_function_names <- all_l_functions |>
    pull(function_name)
  # extract all class function names (will be used in the next step to run them all)
  all_c_function_names <- all_c_functions |>
    pull(function_name)

  # function to calculate a single index for all landscapes in a list
  # landscape_list: list of landscapes
  # current_function: function name as a string, e.g. "lsm_l_landscape"
  calculate_index_all_landscapes <- function(landscape_list, current_function) {
    result <- map2_dfr(
      landscape_list,
      names(landscape_list),
      \(x, y)
      do.call(current_function, list(x)) |>
        mutate(landscape = y)
    )
    return(result)
  }

  # calculate all landscape based metrics  --------------------------------------
  # run all functions (with default arguments) on all the landscapes
  # map_dfr is similar to lapply and runs a functoin for all elements of
  # all_l_function_names. The function it runs is calculate_index_all_landscapes
  # with the list of all patterns (all_patterns_raster) and the current function (.x)
  all_indices_all_landscapes <- map_dfr(
    all_l_function_names,
    ~ calculate_index_all_landscapes(all_patterns_raster, .x)
  )

  # clean up the table for nicer printing
  # select columns and round the results to 3 digits
  all_indices_all_landscapes <- all_indices_all_landscapes |>
    select(metric, value, landscape) |>
    mutate(value = round(value, 3))

  # join with the information from the landscape info table
  all_indices_all_landscapes <- all_indices_all_landscapes |>
    left_join(all_l_functions, by = "metric") |>
    select(-level, -function_name)

  # reformat the table from long to wide format
  all_indices_all_landscapes <- all_indices_all_landscapes |>
    pivot_wider(names_from = landscape, values_from = value)

  # save to clipboard as csv to paste to boxFU sheet
  #all_indices_all_landscapes |>
  #  clipr::write_clip()

  # calculate all class based metrics  --------------------------------------
  # run all functions (with default arguments) on all the landscapes
  all_c_indices_all_landscapes <- map_dfr(
    all_c_function_names,
    ~ calculate_index_all_landscapes(all_patterns_raster, .x)
  )

  # clean up the table for nicer printing
  all_c_indices_all_landscapes <- all_c_indices_all_landscapes |>
    select(metric, class, value, landscape) |>
    mutate(value = round(value, 3))

  #assign type (based on name) to dataset
  all_c_indices_all_landscapes$type <- NA
  for(t in 1:length(types)){
    all_c_indices_all_landscapes$type[str_detect(all_c_indices_all_landscapes$landscape,types[t])] <- types[t]
  }
  all_c_indices_all_landscapes$type <- as.factor(all_c_indices_all_landscapes$type)

  return(all_c_indices_all_landscapes)

}
