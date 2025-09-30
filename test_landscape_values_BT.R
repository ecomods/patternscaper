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
  elongation_y = ey[1],
  seed = NULL
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
  noise_sd = ns[1],
  seed = NULL
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
      noise_radius_sd = nrs[1],
      seed=NULL,
      regular_spots=FALSE,
    )
plot_landscape(test)


#BANDED VEGETATION AT HILLSLOPES

nhills <- sample(x=2:6,size=1)
ht <- sample(x=20:30,size=nhills)
sl <- runif(n=nhills,min=0.1,max=0.3)
nb <- sample(x=4:8, size=1)
xx <- rnorm(n=nhills,mean=1,sd=0.5)
xy <- rnorm(n=nhills,mean=1,sd=0.5)
ns <- runif(n=nhills,min=0,max=0.2)
test <- create_landscape_banded (
    hilltop = ht,
    slope = sl,
    nbands = nb,
    x_ext_hill = xx,
    y_ext_hill = xy,
    noise_sd = ns,
    rotation = 0,
    seed = NULL,
)
plot_landscape(test)
