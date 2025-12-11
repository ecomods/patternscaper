# colours for classes (colour-blind friendly)
library(ggplot2)
class_colors <- c(
  "fingers" = "#000000",
  "sharp" = "#E69F00",
  "diffuse" = "#56B4E9",
  "clustered" = "#009E73",
  "bands" = "#F0E442",
  "random" = "#CC79A7",
  # For self organized
  "bare" = "#E69F00",
  "spots" = "#CC79A7",
  "labyrinth" = "#009E73",
  "gaps" = "#56B4E9",
  "dense" = "#000000"
)

theme_systematic_tests <- function() {
  theme_minimal(base_size = 13) +
    theme(
      strip.text.x = element_text(face = "bold"),
      strip.text.y = element_text(face = "bold"),
      plot.title = element_text(size = 15, face = "bold")
    )
}
