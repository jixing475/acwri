#' Report working directory and acwri/RStudio project
#'
#' @description `proj_sitrep()` reports
#'   * current working directory
#'   * the active acwri project
#'   * the active RStudio Project
#'
#' @description Call this function if things seem weird and you're not sure
#'   what's wrong or how to fix it. Usually, all three of these should coincide
#'   (or be unset) and `proj_sitrep()` provides suggested commands for getting
#'   back to this happy state.
#'
#' @return A named list, with S3 class `sitrep` (for printing purposes),
#'   reporting current working directory, active acwri project, and active
#'   RStudio Project
#' @export
#' @family project functions
#' @examples
#' proj_sitrep()
proj_sitrep <- function() {
  out <- list(
    working_directory = getwd(),
    active_acwri_proj = if (proj_active()) proj_get(),
    active_rstudio_proj = if (rstudioapi::hasFun("getActiveProject")) {
      rstudioapi::getActiveProject()
    }
    ## TODO(?): address home directory to help clarify fs issues on Windows?
    ## home_acwri = fs::path_home(),
    ## home_r = normalizePath("~")
  )
  out <- ifelse(map_lgl(out, is.null), out, as.character(path_tidy(out)))
  structure(out, class = "sitrep")
}

#' @export
print.sitrep <- function(x, ...) {
  keys <- format(names(x), justify = "right")
  purrr::walk2(keys, x, kv_line)

  rstudio_proj_is_active <- !is.null(x[["active_rstudio_proj"]])
  acwri_proj_is_active <- !is.null(x[["active_acwri_proj"]])

  rstudio_proj_is_not_wd <- rstudio_proj_is_active &&
    x[["working_directory"]] != x[["active_rstudio_proj"]]
  acwri_proj_is_not_wd <- acwri_proj_is_active &&
    x[["working_directory"]] != x[["active_acwri_proj"]]
  acwri_proj_is_not_rstudio_proj <- acwri_proj_is_active &&
    rstudio_proj_is_active &&
    x[["active_rstudio_proj"]] != x[["active_acwri_proj"]]

  if (rstudio_available() && !rstudio_proj_is_active) {
    ui_bullets(c(
      "i" = "You are working in RStudio, but are not in an RStudio Project.",
      "i" = "A Project-based workflow offers many advantages. Read more at:",
      " " = "{.url https://docs.posit.co/ide/user/ide/guide/code/projects.html}",
      " " = "{.url https://rstats.wtf/projects}"
    ))
  }

  if (!acwri_proj_is_active) {
    ui_bullets(c(
      "i" = "There is currently no active {.pkg acwri} project.",
      "i" = "{.pkg acwri} attempts to activate a project upon first need.",
      "_" = "Call {.run acwri::proj_get()} to initiate project discovery.",
      "_" = 'Call {.code proj_set("path/to/project")} or
             {.code proj_activate("path/to/project")} to provide an explicit
             path.'
    ))
  }

  if (acwri_proj_is_not_wd) {
    ui_bullets(c(
      "i" = "Your working directory is not the same as the active acwri project.",
      "_" = "Set working directory to the project: {.code setwd(proj_get())}.",
      "_" = "Set project to working directory: {.code acwri::proj_set(getwd())}."
    ))
  }

  if (rstudio_proj_is_not_wd) {
    ui_bullets(c(
      "i" = "Your working directory is not the same as the active RStudio Project.",
      "_" = "Set working directory to the Project:
             {.code setwd(rstudioapi::getActiveProject())}."
    ))
  }

  if (acwri_proj_is_not_rstudio_proj) {
    ui_bullets(c(
      "i" = "Your active RStudio Project is not the same as the active
             {.pkg acwri} project.",
      "_" = "Set active {.pkg acwri} project to RStudio Project:
             {.code acwri::proj_set(rstudioapi::getActiveProject())}.",
      "_" = "Restart RStudio in the active {.pkg acwri} project:
             {.code rstudioapi::openProject(acwri::proj_get())}.",
      "_" = "Open the active {.pkg acwri} project in a new instance of RStudio:
             {.code acwri::proj_activate(acwri::proj_get())}."
    ))
  }

  invisible(x)
}
