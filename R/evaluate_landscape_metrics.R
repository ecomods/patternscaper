# THIS IS NeEDED TO RUN CODE FOR NOW
#-----------------------------------------------
all_c_indices_all_landscapes$type <- NA
#all_c_functions
type <- c("sharp", "fingers", "random", "clustered", "diffuse", "sineband")

#assign  type to dataset
for (t in 1:length(type)) {
  all_c_indices_all_landscapes$type[str_detect(
    all_c_indices_all_landscapes$landscape,
    type[t]
  )] <- type[t]
}
all_c_indices_all_landscapes$type <- as.factor(
  all_c_indices_all_landscapes$type
)
#-----------------------------------------------

#----------------------------------------------------
# function to evaluate and rank the landscape metrics list
#----------------------------------------------------
evaluate_landscape_metrics <- function(
  calculated_metrics,
  metrics_list = "ALL",
  metrics_number = 10,
  method = "coeffvar_all"
) {
  #metrics list not used yet
  top_metrics <- NA

  #number of metrics
  metrics_names <- unique(calculated_metrics$metric)
  num_metrics <- length(metrics_names)
  #number of landscape types
  num_types <- length(unique(all_c_indices_all_landscapes$type))

  #calculate coefficient of variation for each metric
  #once for each landscape separate, and once jointly
  means_types <- data.frame(tapply(
    calculated_metrics$value,
    list(
      as.factor(calculated_metrics$metric),
      as.factor(calculated_metrics$type)
    ),
    mean,
    na.rm = T
  ))
  means_types$all <- tapply(
    calculated_metrics$value,
    as.factor(calculated_metrics$metric),
    mean,
    na.rm = T
  )
  sd_types <- data.frame(tapply(
    calculated_metrics$value,
    list(
      as.factor(calculated_metrics$metric),
      as.factor(calculated_metrics$type)
    ),
    sd,
    na.rm = T
  ))
  sd_types$all <- tapply(
    calculated_metrics$value,
    as.factor(calculated_metrics$metric),
    sd,
    na.rm = T
  )

  #--------------------------------------------------------------------------------------------
  #coefficient of variation for all data
  #however, we do not now, if this comes from a high variation across landscape types or
  #across landscapes in general (e.g. within fingers)
  #--------------------------------------------------------------------------------------------
  if (method == "coeffvar_all") {
    ranking <- rank(sd_types$all / means_types$all, na.last = FALSE)
    top_metrics <- all_c_functions$metric[
      ranking > (num_metrics - metrics_number)
    ] #take only top x
  }

  #--------------------------------------------------------------------------------------------
  #for which metrics do the landscape types significantly differ from each other (with linear model)
  #--------------------------------------------------------------------------------------------
  if (method == "linmod") {
    means_types$p <- NA
    for (i in 1:num_metrics) {
      dat <- all_c_indices_all_landscapes[
        all_c_indices_all_landscapes$metric == all_c_functions$metric[i],
      ]
      if (!is.na(dat$value[i])) {
        model <- lm(data = dat, value ~ type)
        means_types$p[i] <- anova(model)$`Pr(>F)`[1]
      }
    }
    #ranking of the smallest p-values
    ranking <- rank(means_types$p, na.last = TRUE)
    top_metrics <- all_c_functions$metric[ranking <= metrics_number] #take only top x
  }

  #--------------------------------------------------------------------------------------------
  #how strongly do the means vary from the overall mean
  #take four metrics for each landscape types (problem number does not match metrics_number)
  #--------------------------------------------------------------------------------------------
  if (method == "mean_groups") {
    rel_mean_diff <- (means_types[, 1:num_types] - means_types$all) /
      means_types$all

    #for each type, take the two lowest and highest differences from mean
    #problem: sometimes, indices have the same ranking, here I randomly take a sample of two
    mymetrics <- array(data = NA, dim = 4 * num_types)
    for (t in 1:num_types) {
      ranking <- as.integer(rank(rel_mean_diff[, t], na.last = TRUE))
      mymetrics[(t * 4 - 3):(t * 4 - 2)] <- sample(
        metrics_names[ranking <= 2],
        2
      )
      ranking <- as.integer(rank(rel_mean_diff[, t], na.last = FALSE))
      mymetrics[(t * 4 - 1):(t * 4)] <- sample(metrics_names[
        ranking > (num_metrics - 2)
      ])
    }
    top_metrics <- sort(unique(mymetrics))
  }

  return(top_metrics)
}

#test function
evaluate_landscape_metrics(
  calculated_metrics = all_c_indices_all_landscapes,
  metrics_number = 15,
  method = "coeffvar_all"
)
evaluate_landscape_metrics(
  calculated_metrics = all_c_indices_all_landscapes,
  metrics_number = 15,
  method = "linmod"
)
evaluate_landscape_metrics(
  calculated_metrics = all_c_indices_all_landscapes,
  metrics_number = 15,
  method = "mean_groups"
)
