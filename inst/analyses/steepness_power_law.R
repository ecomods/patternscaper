# Visualization of steepness parameter behavior in diffuse treeline landscapes

library(ggplot2)
library(dplyr)
library(patchwork)

# Create data for different steepness values
steepness_values <- seq(0, 1, by = 0.1)
relative_pos <- seq(0, 1, length.out = 100)

# Calculate probabilities for each steepness
prob_data <- expand.grid(
  relative_pos = relative_pos,
  steepness = steepness_values
) |>
  mutate(
    # Current formula: higher steepness = MORE gradual
    prob = pmax(0, 1 - (relative_pos)^steepness),
  )

# Plot current formula
p1 <- ggplot(
  prob_data,
  aes(x = relative_pos, y = prob, color = factor(steepness))
) +
  geom_line(linewidth = 1) +
  labs(
    x = "Relative Position Below Treeline",
    y = "Probability of Tree (1 - (relative_pos)^steepness)",
    color = "Steepness"
  ) +
  theme_minimal() +
  scale_color_viridis_d(option = "plasma") +
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.8, 0.8)
  )

# Generate example landscapes to verify
devtools::load_all()

landscapes_diffuse <- purrr::map(seq(0, 1, by = 0.1), \(x) {
  create_landscape(
    "diffuse",
    name = paste0("steepness: ", as.character(x)),
    steepness = x
  )
})

plots_diffuse <- plot_landscape_list(
  landscapes_diffuse,
  title = "name",
  show_legend = FALSE
)

p1 + plots_diffuse
