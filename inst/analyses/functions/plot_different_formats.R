#--------------------------------------------------------------------
# Helper function to save plots in different formats (jpg, png, pdf)
#--------------------------------------------------------------------
save_plot_multi <- function(
  plot_name,
  directory, 
  filename_base, 
  width = 6, 
  height = 6,
  dpi = 300
) {

  #ensure directory ends with /
  if (!grepl("/$", directory)) {
    directory <- paste0(directory, "/")
  }
  ggsave( #jpg
    filename = paste0(directory, filename_base, ".jpg"),
    plot = plot_name,
    width = width,
    height = height,
    dpi = dpi
  )
  ggsave( #png
    filename = paste0(directory, filename_base, ".png"),
    plot = plot_name,
    width = width,
    height = height,
    dpi = dpi
  )
  ggsave( #pdf
    filename = paste0(directory, filename_base, ".pdf"),
    plot = plot_name,
    width = width,
    height = height
  )
}