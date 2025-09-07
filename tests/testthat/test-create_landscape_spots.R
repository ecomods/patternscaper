# Test spots and tiger stripe landscapes ---------------------------------------------

test_spot <- create_landscape(
  pattern = "spots",
  width = 100,
  height = 100,
  rotation = 0
)
plot_landscape(test_spot)

test_spot2 <- create_spot_vegetation(
  width = 100,
  height = 100,
  n_spots = 5,
  spot_radius = 10,
  rotation = 45
)

test_spot3 <- create_spot_vegetation(
  width = 100,
  height = 100,
  n_spots = 5,
  spot_radius = 10,
  noise_radius_sd = 3,
  rotation = 0
)

test_spot4 <- create_spot_vegetation(
  width = 100,
  height = 100,
  n_spots = 5,
  spot_radius = 10,
  noise_radius_sd = 3,
  rotation = 25
)

create_landscape_clustered_trees(
  treeline_position = 0,
  num_clusters = 5,
  cluster_radius = 5,
  scatter_zone_prop = 1
) |>
  plot_landscape()

spot_list <- list(
  spot1 = test_spot,
  spot2 = test_spot2,
  spot3 = test_spot3,
  spot4 = test_spot4
)

plot_landscape_list(spot_list)


# Banded landscapes

banded1 <- create_landscape_banded()
banded2 <- create_landscape_banded(rotation = 45)
banded3 <- create_landscape_banded(noise_sd = 0.5)
banded4 <- create_landscape_banded(noise_sd = 0)
banded5 <- create_landscape_banded(
  seed = 1,
  hilltop = c(70, 10, 5),
  slope = c(5, 3, 1)
)

banded6 <- create_landscape_banded(
  x_ext_hill = c(0.5, 0.5, 0.5),
  y_ext_hill = c(0.5, 0.5, 0.5)
)

banded7 <- create_landscape_banded(
  x_ext_hill = c(2, 2, 2),
  y_ext_hill = c(2, 2, 2)
)

banded_list <- list(
  banded1 = banded1,
  banded2 = banded2,
  banded3 = banded3,
  banded4 = banded4,
  banded5 = banded5,
  banded6 = banded6,
  banded7 = banded7
)
plot_landscape_list(banded_list)

# Test effect of hilltop
default <- create_landscape_banded()
banded1 <- create_landscape_banded(
  hilltop = c(70, 10, 5)
)
banded2 <- create_landscape_banded(
  hilltop = c(60, 20, 10)
)
banded3 <- create_landscape_banded(
  hilltop = c(0, 0, 0)
)
banded4 <- create_landscape_banded(
  hilltop = c(-10, -10, -10)
)
banded5 <- create_landscape_banded(
  hilltop = c(0.5, 0.5, 0.5),
  slope = c(0.1, 0.1, 0.1),
  nbands = 10
)
hilltop_effect_list <- list(
  default = default,
  banded1 = banded1,
  banded2 = banded2,
  banded3 = banded3,
  banded4 = banded4,
  banded5 = banded5
)
plot_landscape_list(hilltop_effect_list)

create_landscape("banded") |> plot_landscape()
create_landscape("spots") |> plot_landscape()
