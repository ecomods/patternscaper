#--------------------------------------------------------------------
# Load all functions in the package
#--------------------------------------------------------------------
devtools::load_all()

#--------------------------------------------------------------------
# General landscape types and their titles
#--------------------------------------------------------------------

training <- c(200)

layers <- list(c(6),c(8),c(10),
               c(6,6),c(8,8),
               c(10,10),
               c(6,6,6),
               c(8,8,8),
               c(10,10,10))
ntraining <- length(training)
nlayers <- length(layers)
nreps <- 3
metrics_choice <- c("coeffvar_all","mean_groups","fisher_score","kruskal_p")
nmetrics_choice <- length(metrics_choice)
nmetrics <- 10

results_list <- list()
best_metrics_all <- list()

# only those types that refer to ecotones (or random)
ecotone_types = c(
  "random",
  "sharp",
  "diffuse",
  "curvyfingers",
  "clustered",
  "sine_bands"
)
n_ecotones <- length(ecotone_types)

#--------------------------------------------------------------------
# Test Landscapes (always the same)
#--------------------------------------------------------------------
test_landscapes <- create_training_landscapes(
  n = 100,
  seed = 12345,
  patterns = ecotone_types
)

#----------------------------------------------------------
#Training landscapes and their metrics
#----------------------------------------------------------
#generate all training landscapes

for (r in 1:nreps) {
  cat("Replicate: ", r, " of ", nreps, sep = "", "\n")

  for (t in 1:ntraining) {
    cat("Number of landscapes: ",training[t]," (",t," of ",ntraining,")",sep = "","\n")

    #same landscapes for different architectures of the neural net
    training_landscapes <- create_training_landscapes(
      n = training[t],
      seed = 42 + (r - 1),
      patterns = ecotone_types
    )

    # calculate landscape metrics on the landscape level
    training_metrics <- calculate_landscape_metrics(
      training_landscapes,
      level = "landscape"
    )

    # find the 10 best metrics based on coefficient of variation
    for(m in 1:nmetrics_choice){

      cat("Metric: ",metrics_choice[m]," (",m," of ",nmetrics_choice,")",sep = "","\n")

      best_names <- paste0("T", training[t], "_", metrics_choice[m],"_",r,sep="",collapse = "-")

      best_ones <- evaluate_landscape_metrics(
        metrics = training_metrics,
        method = metrics_choice[m],
        metrics_number = nmetrics
      )

      best_metrics_all[[best_names]] <- list(
        training_size = training[t],
        metric = metrics_choice[m],
        replicate = r,
        best_metrics = best_ones
      )

    #----------------------------------------------------------
    # Train neural network model
    #----------------------------------------------------------

      for (l in 1:nlayers) {
        # train a network
        layer_name <- paste(layers[[l]], collapse = "-")
        cat("Number of neurons: ",layer_name," (",l," of ",nlayers,")",sep = "","\n")

        model_neuralnet <- tryCatch(
          {
            train_nn_neuralnet(
              metrics = training_metrics,
              metrics_selected = best_ones,
              hidden_layers = layers[[l]],
              threshold = 0.01,
              stepmax = 1e+05,
              cv_method = "none",
              seed = 42 + (t - 1) * nlayers + (l - 1)
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
        #index <- (r - 1) * ntraining * nbestmetrics * nlayers +
        #  (t - 1) * nbestmetrics * nlayers +
        #  (m - 1) * nlayers + l

        layer_name <- paste(layers[[l]], collapse = "-")
#        result_name <- paste0("T", training[t], "_L", layer_name, "_M",metrics_choice[m],"_R",r,"_total",index,sep="")
        result_name <- paste0("T", training[t], "_L", layer_name, "_M",metrics_choice[m],"_R",r,sep="")

        results_list[[result_name]] <- list(
          training_size = training[t],
          layers = layers[[l]],
          metric = metrics_choice[m],
          replicate = r,
          df1 = df1,
          df2 = df2,
          acc = acc
        )

      }
    }
  }
}

save(results_list, file = "NeuralNet_Test_All.RData")

results_list



# for (t in 1:ntraining) {
#   for (l in 1:3) {
#     cat("L: ",training[t],", L: ",layers[[l]],", Accuracy: ",results_list[[(t - 1) * nlayers + l]]$acc,sep = "","\n")
#   }
# }
#
# for (t in 1:ntraining) {
#   for (l in 1:nlayers) {
#     cat("L: ",training[t],", L: ",layers[[l]],", Class Accuracy: ","\n",sep = "")
#     print(results_list[[(t - 1) * nlayers + l]]$df1)
#   }
# }
#
# for (t in 1:ntraining) {
#   for (l in 1:nlayers) {
#     cat("L: ",training[t],", L: ",layers[[l]],", Confusion Matrix ","\n",sep = ""
#     )
#     print(results_list[[(t - 1) * nlayers + l]]$df2)
#   }
# }
#
# #save(results_list, file = "test.RData")
