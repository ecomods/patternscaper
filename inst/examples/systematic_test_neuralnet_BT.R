#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

#numer of training landscapes
training <- c(50,100,150,200)
ntraining <- length(training)

# ecotone types
ecotone_types = c(
  "random",
  "sharp",
  "diffuse",
  "curvyfingers",
  "clustered",
  "sine_bands"
)
n_ecotones <- length(ecotone_types)


n_input_metrics <- c(5,7,10,13,15,20)
n_n_input_metrics <- length(n_input_metrics)

nlayers <- 9

nreps <- 10
metrics_choice <- c("coeffvar_all", "mean_groups", "fisher_score", "kruskal_p")
nmetrics_choice <- length(metrics_choice)

results_list <- list()
best_metrics_all <- list()

# set seed for reproduce results
set.seed(12345) #for run 1-5
#set.seed(67890) # for run 6-10

#----------------------------------------------------------
#Training landscapes and their metrics
#----------------------------------------------------------
#generate all training landscapes

for (r in 1:nreps) {
  cat("Start - Replicate: ", r, " of ", nreps, sep = "", "\n")

  test_landscapes <- create_training_landscapes(
    n = 100,
    patterns = ecotone_types
  )

  for (t in 1:ntraining) {
    cat("Start - Training with ", training[t], " landscapes (", t, " of ", ntraining, ")", sep = "", "\n")

    #same landscapes for different architectures of the neural net
    training_landscapes <- create_training_landscapes(
      n = training[t],
      patterns = ecotone_types
    )

    # calculate landscape metrics on the landscape level
    training_metrics <- calculate_landscape_metrics(
      training_landscapes,
      level = "landscape"
    )

    # find the 10 best metrics based on coefficient of variation
    for (m in 1:nmetrics_choice) {
      for (nm in 1:n_n_input_metrics) {


        best_names <- paste0(
          "T",
          training[t],
          "_",
          metrics_choice[m],
          "_IM",
          n_input_metrics[nm],
          "_",
          r,
          sep = "",
          collapse = "-"
        )

        best_ones <- evaluate_landscape_metrics(
          metrics = training_metrics,
          method = metrics_choice[m],
          metrics_number = n_input_metrics[nm]
        )

        best_metrics_all[[best_names]] <- list(
          training_size = training[t],
          metric = metrics_choice[m],
          input_metrics = n_input_metrics[nm],
          replicate = r,
          best_metrics = best_ones
        )

        #----------------------------------------------------------
        # Train neural network model
        #----------------------------------------------------------

        for (l in 1:nlayers) {

          adjuster <- n_input_metrics[nm]/5

          layers <- list(
            round(adjuster*c(3),0),
            round(adjuster*c(4),0),
            round(adjuster*c(5),0),
            round(adjuster*c(3, 3),0),
            round(adjuster*c(4, 4),0),
            round(adjuster*c(5, 5),0),
            round(adjuster*c(3, 3, 3),0),
            round(adjuster*c(4, 4, 4),0),
            round(adjuster*c(5, 5, 5),0)
          )

          layer_name <- paste(layers[[l]], collapse = "-")
          cat(
            "T: ", training[t], " (", t, " of ", ntraining,
            "), L: ", layer_name, " (", l, " of ", nlayers,
            "), M: ", metrics_choice[m], " (", m, " of ", nmetrics_choice,
            "), IM: ",n_input_metrics[nm], " (", nm, " of ",n_n_input_metrics,
            "), R: ", r, " of ", nreps,
            sep = "","\n"
          )

          # train a network
          model_neuralnet <- tryCatch(
            {
              train_nn_neuralnet(
                metrics = training_metrics,
                metrics_selected = best_ones,
                hidden_layers = layers[[l]],
                threshold = 0.01,
                stepmax = 1e+05,
                cv_method = "none",
                verbose = F
              )
            },
            error = function(e) {
              cat("Model failed with error:", conditionMessage(e), "\n")
              return(NULL)
            }
          )

          # Skip validation and storage if training failed
          if (is.null(model_neuralnet)) {
            cat("Skipping validation validation\n")
            next
          }

          #--------------------------------------------------------------------
          # Test neural network model
          #--------------------------------------------------------------------

          validation <- tryCatch(
            {
              apply_nn_neuralnet(
                landscapes = test_landscapes,
                nn_model = model_neuralnet
              )
            },
            error = function(e) {
              cat("Model failed with error:", conditionMessage(e), "\n")
              return(NULL)
            }
          )

          # Skip validation and storage if training failed
          if (is.null(model_neuralnet)) {
            cat("Skipping validation validation\n")
            next
          }

          df1 <- data.frame(validation$performance$per_class_metrics)
          df2 <- validation$performance$confusion_matrix
          acc <- validation$performance$accuracy

          #----------------------------------------------------------
          # store results
          #----------------------------------------------------------

          result_name <- paste0(
            "T",
            training[t],
            "_L",
            layer_name,
            "_M",
            metrics_choice[m],
            "_IM",
            n_input_metrics[nm],
            "_R",
            r,
            sep = ""
          )

          results_list[[result_name]] <- list(
            training_size = training[t],
            layers = layers[[l]],
            metric = metrics_choice[m],
            inputmetrics = n_input_metrics[nm],
            replicate = r,
            df1 = df1,
            df2 = df2,
            acc = acc
          )
        }
      }
    }
    #notice: could think about removing results_list after being saved
    file_name <- paste0("NeuralNet_Test_Rep",r,"_T",training[t],".RData",sep = "")
    save(results_list, file = file_name)
  }
}

