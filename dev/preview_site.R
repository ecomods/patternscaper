# Build a persistent local preview without modifying the tracked docs/ site.
#
# Run without arguments for a lazy site refresh:
#   Rscript dev/preview_site.R
#
# Rebuild the complete preview from a clean destination:
#   Rscript dev/preview_site.R clean
#
# Rebuild only the homepage:
#   Rscript dev/preview_site.R home
#
# Pass an article name to rebuild only that article:
#   Rscript dev/preview_site.R patternscaper

args <- commandArgs(trailingOnly = TRUE)
destination <- "_site-preview"
destination_path <- file.path(
  normalizePath(".", winslash = "/", mustWork = TRUE),
  destination
)

if (!requireNamespace("patternscaper", quietly = TRUE)) {
  cli::cli_abort(c(
    "The local package must be installed before previewing the site.",
    "i" = "Run {.run pak::local_install(upgrade = FALSE)} once, then retry."
  ))
}

override <- list(destination = destination)

if (length(args) > 1L) {
  cli::cli_abort("Supply at most one page name.")
} else if (length(args) == 0L) {
  pkgdown::build_site(
    lazy = TRUE,
    override = override,
    preview = FALSE,
    devel = TRUE,
    new_process = FALSE,
    install = FALSE,
    quiet = FALSE
  )
} else if (identical(args[[1]], "clean")) {
  pkgdown::build_site_github_pages(
    dest_dir = destination,
    clean = TRUE,
    install = FALSE,
    new_process = FALSE
  )
} else if (identical(args[[1]], "home")) {
  pkgdown::build_home(
    override = override,
    preview = FALSE,
    quiet = FALSE
  )
} else {
  pkgdown::build_article(
    args[[1]],
    lazy = FALSE,
    new_process = FALSE,
    override = override,
    quiet = FALSE
  )
}

pkgdown::preview_site(path = destination_path, preview = TRUE)
