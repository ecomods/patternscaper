# Contributing to patternscaper

This outlines how to propose a change to patternscaper.

## Fixing typos

You can fix typos, spelling mistakes, or grammatical errors using the GitHub web interface and submit the change as a pull request, as long as you edit the _source_ file.
This generally means editing [roxygen2 comments](https://roxygen2.r-lib.org/articles/roxygen2.html) in an `.R` file, not the generated `.Rd` file.
You can find the `.R` file that generates the `.Rd` by reading the comment in the first line.

## Bigger changes

If you want to make a bigger change, first file an issue and make sure someone from the team agrees that it is needed.
If you have found a bug, please file an issue that illustrates the bug with a minimal
[reprex](https://www.tidyverse.org/help/#reprex) (this will also help you write a unit test, if needed).
See our guide on [how to create a great issue](https://code-review.tidyverse.org/issues/) for more advice.

### Pull request process

*   Fork the package and clone onto your computer. If you haven't done this before, we recommend using `usethis::create_from_github("ecomods/patternscaper", fork = TRUE)`.

*   Install all development dependencies with `devtools::install_dev_deps()`, and then make sure the package passes R CMD check by running `devtools::check()`.
    If R CMD check does not pass cleanly, ask for help before continuing.
*   Create a Git branch for your pull request (PR). We recommend using `usethis::pr_init("brief-description-of-change")`.

*   Make your changes, commit to git, and then create a PR by running `usethis::pr_push()`, and following the prompts in your browser.
    The title of your PR should briefly describe the change.
    The body of your PR should contain `Fixes #issue-number`.

### Code style

*   New code should follow the tidyverse [style guide](https://style.tidyverse.org).
    You can use [Air](https://posit-dev.github.io/air/) to apply this style, but please do not restyle code that has nothing to do with your PR.

*   We use [roxygen2](https://cran.r-project.org/package=roxygen2) for documentation. Roxygen Markdown is not enabled, so follow the existing Rd-style markup in source comments.

*   We use [testthat](https://cran.r-project.org/package=testthat) for unit tests.
    Contributions with test cases included are easier to accept.

## Code of Conduct

Please note that the patternscaper project is released with a
[Contributor Code of Conduct](https://ecomods.github.io/patternscaper/CODE_OF_CONDUCT.html). By contributing to this
project you agree to abide by its terms.
