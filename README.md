
<!-- README.md is generated from README.Rmd. Please edit that file -->

# acwri

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

acwri is an academic writing tools package for R users. It integrates
various utilities to streamline the academic writing workflow.

## Installation

You can install the development version of acwri from GitHub with:

``` r
# install.packages("pak")
pak::pak("jixing475/acwri")
```

## Usage

``` r
library(acwri)

# Extract track changes from a Word document
# extract_docx_revisions("manuscript.docx", output = "revisions.md")
```

## Features

### Word Revisions Extraction

Extract all types of revisions (comments, deletions, insertions, and
formatting changes) from a Word document and save them into a Markdown
file.

``` r
# Return results as a character vector
revisions <- extract_docx_revisions("manuscript.docx")

# Or save to a file
extract_docx_revisions("manuscript.docx", output = "changes.md")
```

This feature requires Python and the `docx2python` package. Setting up a
virtual environment in `inst/docx2md/.venv` is recommended. \`\`\`

## Code of Conduct

Please note that the acwri project is released with a Contributor Code
of Conduct. By contributing to this project, you agree to abide by its
terms.
