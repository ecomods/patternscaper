
dir_systematic <- "inst/analyses/data/systematic_tests/"
dir_nn_approach <- c("nn_metrics/","keras/")
dir_system <- c("ecotones/","selforg/")
prefix <- c("nn_","keras_")
approach <- c("metrics","keras")
system <- c("ecotones","selforga")
n_a <- length(dir_nn_approach)
n_s <- length(dir_system)
n_tot <- n_a * n_s

data_systematic_tests <- list()
data_systematic_tests_worst <- list()

for (a in 1:n_a){
  for (s in 1:n_s){
    data_systematic_tests[[i]] <- read.csv(
      paste(dir_systematic,dir_nn_approach[a],dir_system[s],
      prefix[a],
      "systematic_summary_accuracy.csv",
      sep=""))
      data_systematic_tests[[i]]$approch <- approach[a]
      data_systematic_tests[[i]]$system <- system[s]
    data_systematic_tests_worst[[i]] <- read.csv(
      paste(dir_systematic,dir_nn_approach[a],dir_system[s],
      prefix[a],
      "systematic_summary_worst_classes.csv",
      sep=""))
      data_systematic_tests[[i]]$approch <- approach[a]
      data_systematic_tests[[i]]$system <- system[s]
      data_systematic_tests_worst[[i]]$approch <- approach[a]
      data_systematic_tests_worst[[i]]$system <- system[s]
      i <- i+1
  }
}
data_systematic_tests
data_systematic_tests_worst

# evaluate entries
data_summary <- list()
for (i in 1:n_tot) {
  df <- data_systematic_tests[[i]]
  df_worst <- data_systematic_tests_worst[[i]]

  # highest accuracy (and for which setting)
  max_accuracy <- max(df$mean_accuracy, na.rm = TRUE)
  best <- df %>%
    dplyr::filter(mean_accuracy == max_accuracy)

  # lowest accuracy (and for which setting)
  min_mean_accuracy <- min(df$mean_accuracy, na.rm = TRUE)
  worst_mean_accuracy <- df %>%
    dplyr::filter(mean_accuracy == min_mean_accuracy)  

  # what if only 50 landscapes are used for training
  df_50 <- df %>%
    dplyr::filter(n_landscapes == 50)
  max_accuracy_50 <- max(df_50$mean_accuracy, na.rm = TRUE)
  perc_90 <- quantile(df$mean_accuracy, 0.90,na.rm = TRUE)
  best_50 <- df_50 %>%
    dplyr::filter(mean_accuracy == max_accuracy_50)
   perc_90_50 <- quantile(df_50$mean_accuracy, 0.90,na.rm = TRUE) 
  
  # mean accuracy dependent on number of training landscapes and Inputs/Epochs
  if(df$approch[1]==approach[1]){
    df_mean_accuracy <- df %>%
      group_by(n_landscapes,Inputs) %>%
        dplyr::summarise(
          mean_accuracy = mean(mean_accuracy, na.rm = TRUE),
          .groups = "drop"
    )
    df_max_accuracy_addon <- df %>%
      group_by(n_landscapes,Inputs,metric ) %>%
        dplyr::summarise(
          mean_accuracy = max(mean_accuracy, na.rm = TRUE),
          .groups = "drop"
    )
    df_min_accuracy <- df %>%
      group_by(n_landscapes,Inputs) %>%
        dplyr::summarise(
          mean_accuracy = min(mean_accuracy, na.rm = TRUE),
          .groups = "drop"
    )
    df_max_accuracy <- df %>%
      group_by(n_landscapes,Inputs) %>%
        dplyr::summarise(
          max_accuracy = max(mean_accuracy, na.rm = TRUE),
          .groups = "drop"
    )
    df_max_worst_accuracy <- df_worst %>%
      group_by(n_landscapes,Inputs) %>%
        dplyr::summarise(
          max_accuracy = max(mean_worst_precision , na.rm = TRUE),
          .groups = "drop"
    )
  } else{
    df_mean_accuracy <- df %>%
      group_by(n_landscapes,epochs) %>%
        dplyr::summarise(
          mean_accuracy = mean(mean_accuracy, na.rm = TRUE),
          .groups = "drop"
    )
    df_max_accuracy_addon <- df %>%
      group_by(n_landscapes,epochs,learning_rate) %>%
        dplyr::summarise(
          mean_accuracy = max(mean_accuracy, na.rm = TRUE),
          .groups = "drop"
    )
    df_min_accuracy <- df %>%
      group_by(n_landscapes,epochs,learning_rate) %>%
        dplyr::summarise(
          mean_accuracy = min(mean_accuracy, na.rm = TRUE),
          .groups = "drop"
    )   
    df_max_accuracy <- df %>%
      group_by(n_landscapes,epochs) %>%
        dplyr::summarise(
          max_accuracy = max(mean_accuracy, na.rm = TRUE),
          .groups = "drop"
    )
    df_max_worst_accuracy <- df_worst %>%
      group_by(n_landscapes,epochs) %>%
        dplyr::summarise(
          max_accuracy = max(mean_worst_precision , na.rm = TRUE),
          .groups = "drop"
    )
  }
  # store data
  data_summary[[i]] <- list(
  #  data = df,
    max_accuracy = max_accuracy,
    min_mean_accuracy = min_mean_accuracy,
    percentile90 = perc_90,
    best = best,
    worst_mean_accuracy = worst_mean_accuracy,
    max_accuracy_50 = max_accuracy_50,
    percentile90_50 <- perc_90_50,
    best_50 = best_50,
    mean_accuracy_grouped = df_mean_accuracy,
    max_accuracy_grouped = df_max_accuracy,
    max_worst_accuracy_grouped = df_max_worst_accuracy,
    max_accuracy_grouped_addon = df_max_accuracy_addon,
    min_accuracy_grouped_addon = df_min_accuracy
  )
}

#---------------------------------------------
# values for manuscript
#---------------------------------------------

# 1. ecotone landscapes: metrics 

# maximal accuracy
round(data_summary[[1]]$max_accuracy,2)
# effect of number of landscapes and input neurons
print(n=24,round(data_summary[[1]]$mean_accuracy_grouped,2))
# class with worst accuracy
print(n=24,round(data_summary[[1]]$max_worst_accuracy_grouped,2))

# 2. ecotone landscapes: pixel 

# maximal accuracy
round(data_summary[[3]]$max_accuracy,2)
# maximal accuracy for learning rate of 10^-2
print(n=45,data_summary[[3]]$max_accuracy_grouped_addon %>% dplyr::filter(learning_rate == 0.01))
# effect of number of landscapes and epochs
print(round(data_summary[[3]]$mean_accuracy_grouped,2))
# class with worst accuracy
print(round(data_summary[[3]]$max_worst_accuracy_grouped,2))

# 3. selforga landscapes: metrics 

# maximal accuracy
round(data_summary[[2]]$max_accuracy,2)
# minimal mean accuracy
print(n=96,data_summary[[2]]$min_accuracy_grouped_addon)
