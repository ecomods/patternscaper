# Title:   Colourblind check for discrete landscape palettes
# Date:    2026-07-08
# Author:  Selina Baldauf
# Purpose: Show candidate discrete landscape palettes as swatches and simulate
#          colour-vision deficiencies to judge how colourblind-friendly they are.

library(tidyverse)
library(colorspace)
library(viridisLite)
library(patchwork)

# Candidate palettes ----------------------------------------------------------
# Ecological binary pair = pale bare ground + dark vegetation. The qualitative
# sets are recognised colourblind-safe scientific standards.

okabe_ito <- c(
  "#E69F00",
  "#56B4E9",
  "#009E73",
  "#F0E442",
  "#0072B2",
  "#D55E00",
  "#CC79A7",
  "#000000"
)
tol_muted <- c(
  "#CC6677",
  "#332288",
  "#DDCC77",
  "#117733",
  "#88CCEE",
  "#882255",
  "#44AA99",
  "#999933",
  "#AA4499"
)

palettes <- list(
  current = c(
    "#E5E59F",
    "#005C29",
    "#8DA0CB",
    "#E78AC3",
    "#A6D854",
    "#FFD92F",
    "#E5C494",
    "#B3B3B3",
    "#7570B3",
    "#D95F02"
  ),
  okabe_ito = okabe_ito,
  tol_muted = tol_muted,
  # viridis is CVD-safe but perceptually ordered, so nominal classes can read as
  # ranked; fine for the binary case, weaker for many categories.
  viridis = viridis(10),
  # ecological pair + Okabe-Ito for extra classes (blue first, so class 3 is
  # maximally distinct from the two greens)
  hybrid_okabe = c(
    "#E5E59F",
    "#005C29",
    "#56B4E9",
    "#D55E00",
    "#0072B2",
    "#CC79A7",
    "#E69F00",
    "#009E73"
  ),
  # same idea, extras from Tol muted (softer, more map-friendly)
  hybrid_tol = c(
    "#E5E59F",
    "#005C29",
    "#88CCEE",
    "#CC6677",
    "#332288",
    "#AA4499",
    "#44AA99",
    "#DDCC77"
  ),
  custom = c(
    "#E5E59F",
    "#005C29",
    "#88CCEE",
    "#D55E00",
    "#CC79A7",
    "#56B4E9",
    "#E69F00",
    "#009E73"
  )
)

# Pass any two colours (bare, vegetation) to try them out
set.seed(42)
plot_landscapes_in_colours(palettes$hybrid_okabe[c(2, 4)])

# Simulate colour vision deficiencies -----------------------------------------

cvd_funs <- list(
  normal = identity,
  deuteranopia = deutan,
  protanopia = protan,
  tritanopia = tritan
)

swatches <- palettes |>
  enframe(name = "palette", value = "hex") |>
  unnest_longer(hex, indices_to = "index") |>
  crossing(cvd = names(cvd_funs)) |>
  mutate(
    shown = map2_chr(cvd, hex, \(type, colour) cvd_funs[[type]](colour))
  ) |>
  mutate(
    palette = fct_inorder(palette),
    cvd = fct_relevel(cvd, names(cvd_funs))
  )

# Swatch plot: palettes as rows, CVD types stacked within each ----------------

ggplot(swatches, aes(x = index, y = fct_rev(cvd), fill = shown)) +
  geom_tile(colour = "white", linewidth = 0.6) +
  scale_fill_identity() +
  scale_x_continuous(breaks = seq_len(max(swatches$index))) +
  facet_wrap(vars(palette), ncol = 1, strip.position = "left") +
  labs(x = "colour index", y = NULL) +
  theme_minimal(base_size = 14) +
  theme(
    panel.grid = element_blank(),
    strip.text.y.left = element_text(angle = 0, face = "bold"),
    aspect.ratio = NULL
  )


# A chosen colour set on a synthetic multi-class landscape --------------------
# Landscapes are binary by design, so >2 classes never occur naturally. This
# builds a synthetic map -- a smoothed random field cut into contiguous classes
# -- only to preview how a multi-colour palette reads. The number of classes
# equals the number of colours passed, so give it 3 or 4 colours.

plot_multiclass_landscape <- function(colours, size = 100) {
  n_class <- length(colours)

  # Coarse random field, smoothly upsampled -> contiguous patches
  coarse <- terra::rast(
    nrows = 10,
    ncols = 10,
    xmin = 0,
    xmax = size,
    ymin = 0,
    ymax = size
  )
  terra::values(coarse) <- rnorm(terra::ncell(coarse))
  field <- terra::disagg(coarse, fact = size / 10, method = "bilinear")

  terra::as.data.frame(field, xy = TRUE) |>
    set_names(c("x", "y", "value")) |>
    mutate(
      class = value |>
        cut(
          breaks = quantile(value, seq(0, 1, length.out = n_class + 1)),
          include.lowest = TRUE,
          labels = FALSE
        ) |>
        factor()
    ) |>
    ggplot(aes(x = x, y = y, fill = class)) +
    geom_raster() +
    scale_fill_manual(values = colours) +
    coord_equal() +
    theme_minimal() +
    theme(
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank()
    )
}

# Examples: pass any 2, 3, or 4 colours -----------------------------------------
set.seed(42)

a <- plot_multiclass_landscape(palettes$hybrid_okabe[1:7])
b <- plot_multiclass_landscape(palettes$hybrid_tol[1:7])

a + b + plot_layout(ncol = 2)

# A chosen colour pair on real landscapes -------------------------------------
# Generate three different binary landscapes and fill them with a chosen pair
# (bare ground, vegetation) to judge how the colours read on actual patterns.

pkgload::load_all(quiet = TRUE) # run from the package root

plot_landscapes_in_colours <- function(
  colours,
  patterns = c("sharp", "labyrinth", "spots")
) {
  patterns |>
    set_names() |>
    map(\(p) create_landscape(p, width = 100, height = 100)) |>
    imap(\(ls, p) {
      terra::as.data.frame(ls$data, xy = TRUE) |>
        set_names(c("x", "y", "value")) |>
        mutate(pattern = p)
    }) |>
    list_rbind() |>
    mutate(
      pattern = fct_inorder(pattern),
      cover = factor(value, levels = c(0, 1), labels = c("bare", "vegetation"))
    ) |>
    ggplot(aes(x = x, y = y, fill = cover)) +
    geom_raster() +
    scale_fill_manual(values = set_names(colours, c("bare", "vegetation"))) +
    facet_wrap(vars(pattern)) +
    coord_equal() +
    theme_minimal() +
    theme(
      axis.text = element_blank(),
      axis.title = element_blank(),
      panel.grid = element_blank()
    )
}
