#' @keywords internal
"_PACKAGE"

## acwri namespace: start
#' @import fs
#' @import rlang
#' @importFrom glue glue glue_collapse glue_data
#' @importFrom lifecycle deprecated
#' @importFrom purrr map map_chr map_lgl map_int
#' @importFrom utils available.packages
## acwri namespace: end
NULL

#' Options consulted by acwri
#'
#' @description
#' User-configurable options consulted by acwri, which provide a mechanism
#' for setting default behaviors for various functions.
#'
#' If the built-in defaults don't suit you, set one or more of these options.
#' Typically, this is done in the `.Rprofile` startup file, which you can open
#' for editing with [edit_r_profile()] - this will set the specified options for
#' all future R sessions. Your code will look something like:
#'
#' ```
#' options(
#'   acwri.description = list(
#'     "Authors@R" = utils::person(
#'       "Jane", "Doe",
#'       email = "jane@example.com",
#'       role = c("aut", "cre"),
#'       comment = c(ORCID = "YOUR-ORCID-ID")
#'     ),
#'     License = "MIT + file LICENSE"
#'   ),
#'   acwri.destdir = "/path/to/folder/", # for use_course(), create_from_github()
#'   acwri.protocol = "ssh", # Use ssh git protocol
#'   acwri.overwrite = TRUE # overwrite files in Git repos without confirmation
#' )
#' ```
#'
#' @section Options for the acwri package:
#'
#' - `acwri.description`: customize the default content of new `DESCRIPTION`
#'   files by setting this option to a named list.
#'   If you are a frequent package developer, it is worthwhile to pre-configure
#'   your preferred name, email, license, etc. See the example above for more details.
#'
#' - `acwri.destdir`: Default directory in which to place new projects
#'   downloaded by [use_course()] and [create_from_github()].
#'   If this option is unset, the user's Desktop or similarly conspicuous place
#'   will be used.
#'
#' - `acwri.protocol`: specifies your preferred transport protocol for Git.
#'   Either "https" (default) or "ssh":
#'     * `acwri.protocol = "https"` implies `https://github.com/<OWNER>/<REPO>.git`
#'     * `acwri.protocol = "ssh"` implies `git@github.com:<OWNER>/<REPO>.git`
#'
#'   You can also change this for the duration of your R session with
#'   [use_git_protocol()].
#'
#' - `acwri.overwrite`: If `TRUE`, acwri overwrites an existing file without
#'   asking for user confirmation if the file is inside a Git repo. The
#'   rationale is that the normal Git workflow makes it easy to see and
#'   selectively accept/discard any proposed changes.
#'
#' - `acwri.quiet`: Set to `TRUE` to suppress user-facing messages. Default
#'   `FALSE`.
#'
#' - `acwri.allow_nested_project`: Whether or not to allow
#'   you to create a project inside another project. This is rarely a good idea,
#'   so this option defaults to `FALSE`.
#'
#' @name acwri_options
NULL

release_bullets <- function() {
  c(
    "Check that `use_code_of_conduct()` is shipping the latest version of the Contributor Covenant (<https://www.contributor-covenant.org>)."
  )
}
