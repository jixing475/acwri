devtools::load_all()
library(fs)
library(testthat)

options(acwri.destdir = NULL)

cp <- function(x = "") path(acwri:::conspicuous_place(), x)
cleanup <- function(regexp) {
  outdir <- dir_ls(cp(), regexp = regexp, type = "directory")
  dir_delete(outdir)
  outfile <- dir_ls(cp(), regexp = regexp, type = "file")
  file_delete(outfile)
  invisible()
}

## use_course() simple usage ----
# Should see:
# 1. Menu confirming download to conspicuous place
# 2. Menu approving deletion of ZIP file
use_course("r-lib/rematch2")

cleanup("rematch2-")

## use_course() overwriting existing file ----
use_zip("r-lib/rematch2", destdir = cp(), cleanup = FALSE)
use_course("r-lib/rematch2", destdir = cp())
# Should see:
# Query whether to overwrite pre-existing file
# "No" aborts
# "Yes" proceeds
cleanup("rematch2-")

# download of a DropBox folder
# acwri-manual-test folder JB created for development
dropbox <- "https://www.dropbox.com/sh/iep7x58py4vpa9n/AAAju4kvYCjjD6s8WJqyICHBa?dl=1"
use_zip(dropbox, destdir = cp())
expect_true(dir_exists(cp("acwri-manual-test")))
cleanup("acwri-manual-test")

## the ZIP URL favored by devtools
gh_url <- "http://github.com/r-lib/rematch2/zipball/master/"
folder <- use_zip(gh_url, destdir = cp(), cleanup = FALSE)
(zipfile <- dir_ls(cp(), regexp = "r-lib-rematch2-.*[.]zip"))
expect_length(zipfile, 1)
cleanup("r-lib-rematch2-")
