library(patchwork)
# load all functions
devtools::load_all()

# Test individual landscape functions

# Test clusters ----------------------------------------------------------------
clusters1 <- create_landscape_clusters()
clusters2 <- create_landscape_clusters(
  num_clusters = 5,
  cluster_radius = 10,
  elongation_x = 1.5,
  elongation_y = 0.5,
  scatter_zone_prop = 0.2
)
# rotations
clusters1_rot <- create_landscape_clusters(rotation = 45)
clusters2_rot <- create_landscape_clusters(rotation = 45, seed = 12345)
clusters3_rot <- create_landscape_clusters(
  num_clusters = 5,
  cluster_radius = 10,
  elongation_x = 1.5,
  elongation_y = 0.5,
  scatter_zone_prop = 0.2,
  rotation = 45
)

# make plots
p1 <- plot_landscape(clusters1)
p2 <- plot_landscape(clusters2)
p3 <- plot_landscape(clusters1_rot)
p4 <- plot_landscape(clusters2_rot)
p5 <- plot_landscape(clusters3_rot)

# combine plots
p1 + p2 + p3 + p4 + p5 + plot_layout(guides = "collect")

#
landscape_1 <- create_landscape_clusters(
  rotation = 0
) |>
  plot_landscape(title = "100x100, no rotation")
landscape_2 <- create_landscape_clusters(
  rotation = 45
) |>
  plot_landscape(title = "100x100, 45 degrees rotation")
landscape_3 <- create_landscape_clusters(
  width = 80,
  height = 60,
  rotation = 0
) |>
  plot_landscape(title = "80x60, no rotation")
landscape_4 <- create_landscape_clusters(
  width = 60,
  height = 80,
  rotation = 45
) |>
  plot_landscape(title = "60x80, 45 degrees rotation")
landscape_combined <- landscape_1 +
  landscape_2 +
  landscape_3 +
  landscape_4 +
  plot_layout(guides = "collect")


plot_landscape(landscape_rotated)
