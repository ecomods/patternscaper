# Purpose: Binarize images for self-organized landscapes

library(tidyverse)

pic_dir <- "inst/analyses/selfOrga_results_class/Pics"
pic_names <- list.files(pic_dir, full.names = TRUE)

# Extract author and pattern information from the pics
pic_authors <- basename(pic_names) |>
  #everything before the first underscore
  str_extract("^[^_]+") |>
  str_to_lower()

pic_patterns <- basename(pic_names) |>
  #everything between last _ and .png
  str_extract("_[^_]+(?=\\.png$)") |>
  str_remove_all("_") |>
  str_to_lower()

# Read in all the pictures
all_pics <- map(pic_names, png::readPNG)

# Binarized the images based
# Different binarization for different authors
binary_imgs <- map(
  seq_along(all_pics),
  \(i) {
    img <- all_pics[[i]]
    author <- pic_authors[i]

    R <- img[,, 1]
    G <- img[,, 2]
    B <- img[,, 3]
    V <- pmax(R, G, B)

    if (author == "meron") {
      binary_img <- ifelse(
        (V < 0.1 | # very dark
          G > R * 1.02 & G > B * 1.02) | # normal green
          (G > R * 0.75 & G > B * 0.75 & V < 0.2), # dark green
        1,
        0
      )
    } else if (author == "mander") {
      binary_img <- ifelse(
        (V < 0.65),
        1,
        0
      )
    } else {
      stop("Unknown author: ", author)
    }

    return(binary_img)
  }
)

# Turn them into landscape objects
pics_landscapes <- map(
  seq_along(binary_imgs),
  \(i) {
    # convert to a landscape object
    l <- landscape(
      data = binary_imgs[[i]],
      name = pic_authors[i],
      pattern = pic_patterns[i]
    )
  }
)
