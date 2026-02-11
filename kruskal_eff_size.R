devtools::load_all()
landscapes <- create_landscapes()
metrics <- calculate_landscape_metrics(landscapes)


# Define the manual implementation
kruskal_effsize_manual <- function(data, formula) {
  response <- all.vars(formula)[1]
  group <- all.vars(formula)[2]

  kt <- kruskal.test(formula, data = data)

  n <- nrow(data)
  effsize <- kt$statistic / ((n^2 - 1) / (n + 1))
  effsize
}

# Approach 2: P-value based (from the code snippet)
kruskal_manual2 <- function(data, formula) {
  kt <- kruskal.test(formula, data = data)
  n <- nrow(data)
  groups <- length(unique(data[[all.vars(formula)[2]]]))
  chi <- qchisq(kt$p.value, groups - 1, lower.tail = FALSE)
  chi / (n - 1)
}

# Compare on your actual data
manual <- metrics |>
  dplyr::group_by(metric) |>
  tidyr::nest() |>
  dplyr::mutate(
    effsize_manual = purrr::map_dbl(data, \(df) {
      df <- df[!is.na(df$value), ]
      if (length(unique(df$pattern)) < 2) {
        return(NA_real_)
      }
      tryCatch(
        kruskal_effsize_manual(df, value ~ pattern)$effsize,
        error = function(e) NA_real_
      )
    })
  ) |>
  dplyr::arrange(dplyr::desc(effsize_manual)) |>
  mutate(id_manual = row_number())

manual_2 <- metrics |>
  dplyr::group_by(metric) |>
  tidyr::nest() |>
  dplyr::mutate(
    effsize_manual2 = purrr::map_dbl(data, \(df) {
      df <- df[!is.na(df$value), ]
      if (length(unique(df$pattern)) < 2) {
        return(NA_real_)
      }
      tryCatch(
        kruskal_manual2(df, value ~ pattern),
        error = function(e) NA_real_
      )
    })
  ) |>
  dplyr::arrange(dplyr::desc(effsize_manual2)) |>
  mutate(id_manual2 = row_number())


kruskal_results <- metrics |>
  dplyr::group_by(metric) |>
  tidyr::nest() |>
  dplyr::mutate(
    kruskal_effsize = purrr::map_dbl(data, \(df) {
      df <- df[!is.na(df$value), ]
      if (length(unique(df$pattern)) < 2) {
        return(NA_real_)
      }
      tryCatch(
        rstatix::kruskal_effsize(value ~ pattern, data = df)$effsize,
        error = function(e) NA_real_
      )
    })
  ) |>
  dplyr::arrange(dplyr::desc(kruskal_effsize)) |>
  mutate(id_kruskal = row_number())


left_join(kruskal_results, manual, by = "metric") |>
  left_join(manual_2, by = "metric") |>
  mutate(id_diff = id_kruskal - id_manual) |>
  arrange(-id_diff)
