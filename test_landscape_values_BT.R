#Tests to determine useful ranges for
#landscape parameters for
#clustered, sine_bands, spots, banded


# load all functions
devtools::load_all()

#CLUSTERS
n = 1
tp <- runif(n,0.4,0.6)
nc <- round(runif(n,5,15),0)
cr <- round(runif(n,3,7),0)
szp <- runif(n,0.2,1)
ex <- runif(n,0.5,1.5)
ey <- runif(n,0.5,1.5)

test <- create_landscape_clustered_trees(
  treeline_position = tp[1],
  num_clusters = nc[1],
  cluster_radius = cr[1],
  scatter_zone_prop = szp[1],
  elongation_x = ex[1],
  elongation_y = ey[1]
)
plot_landscape(test)


#SINEBANDS
n = 1
tp <- runif(n,0.3,0.5)
bz <- runif(n,0.2,0.5)
bt <- round(runif(n,2,7),0)
bs <- round(runif(n,5,15),0)
f <- runif(n,0.1,0.3)
a <- round(runif(n,0,6),0)
ns <- runif(n,0,1.5)

test <- create_landscape_sine_bands(
  treeline_position = tp[1],
  band_zone_prop = bz[1],
  band_thickness = bt[1],
  band_spacing = bs[1],
  frequency = f[1],
  amplitude = a[1],
  noise_sd = ns[1]
)
plot_landscape(test)

# SPOTS
#devtools::load_all()
ns = round(runif(n,10,30),0)
sr = round(runif(n,5,12),0)
nrs= runif(n,0,2)

test <- create_landscape_spots(
      n_spots = ns[1],
      spot_radius = sr[1],
      spot_jitter = 1,
      noise_radius_sd = nrs[1]
      regular_spots=FALSE,
    )
plot_landscape(test)


#BANDED VEGETATION AT HILLSLOPES
test <- create_landscape_banded (
  nhills = sample(1:5,size=1),
  nbands = sample(3:8,size=1),
  regular_hilltop = sample(c(TRUE, FALSE), size=1),
  top_elevation_sd = runif(n=1,min=0,max=3),
  x_ext_hill_sd = runif(n=1,min=0,max=0.5),
  y_ext_hill_sd = runif(n=1,min=0,max=0.5)
  rotation=43,
)
plot_landscape(test)


#TO DO: PUT ThIS To CORRECT FILE
test <- create_landscape_labyrinth (
  frequency = runif(n=1,1,4),
  veg_threshold = runif(n=1,0.4,0.5),
  band_fuzziness = runif(n=1,0,0.1),
  octaves = sample(1:3,size=1)
)
plot_landscape(test)

