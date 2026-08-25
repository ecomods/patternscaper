# Build a persistent local preview without modifying the tracked docs/ site.
#
# Run without arguments for a lazy site refresh:
#   Rscript dev/preview_site.R
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

if (length(args) == 0L) {
  pkgdown::build_site(
    lazy = TRUE,
    override = override,
    preview = FALSE,
    devel = TRUE,
    new_process = FALSE,
    install = FALSE,
    quiet = FALSE
  )
} else if (length(args) == 1L) {
  pkgdown::build_article(
    args[[1]],
    lazy = FALSE,
    new_process = FALSE,
    override = override,
    quiet = FALSE
  )
} else {
  cli::cli_abort("Supply at most one article name.")
}

pkgdown::preview_site(path = destination_path, preview = TRUE)
