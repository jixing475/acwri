#' Extract Track Changes from Word Document
#'
#' @description
#' Extract all track changes (revisions) from a Word document (.docx), including
#' comments, deletions, insertions, formatting changes, and paragraph changes,
#' and output in Markdown format.
#'
#' This function wraps the Python script `extract_docx_track_changes.py` and
#' requires the user to configure a Python environment with the `docx2python`
#' package installed.
#'
#' @param docx_path Path to the Word document to process.
#' @param output Optional path to the output Markdown file. If not specified,
#'   the function returns a character vector.
#' @param python_path Path to the Python executable. Defaults to the bundled
#'   virtual environment if it exists, otherwise searches for system python3.
#' @param quiet Whether to run silently. Defaults to `FALSE`.
#'
#' @return If `output` is specified, returns `NULL` (invisibly);
#'   otherwise returns a character vector containing the Markdown content.
#'
#' @section Python Environment Setup:
#' This function depends on the Python package `docx2python`. Setup steps:
#' ```bash
#' # In the inst/docx2md directory
#' uv venv .venv --python 3.12
#' source .venv/bin/activate
#' uv pip install docx2python
#' ```
#'
#' @examples
#' \dontrun{
#' # Return character vector
#' result <- extract_docx_revisions("manuscript.docx")
#' cat(result, sep = "\n")
#'
#' # Save to file
#' extract_docx_revisions("manuscript.docx", output = "changes.md")
#'
#' # Use custom Python path
#' extract_docx_revisions(
#'   "manuscript.docx",
#'   python_path = "/usr/bin/python3"
#' )
#' }
#'
#' @export
extract_docx_revisions <- function(
  docx_path,
  output = NULL,
  python_path = NULL,
  quiet = FALSE
) {
  # Validate input file
  docx_path <- user_path_prep(docx_path)
  if (!file_exists(docx_path)) {
    ui_abort(c(
      "x" = "File does not exist: {.path {docx_path}}",
      "i" = "Please check if the file path is correct."
    ))
  }

  # Get Python script path
  script_path <- find_docx_script()

  # Get Python executable path
  if (is.null(python_path)) {
    python_path <- find_default_python()
  }

  # Validate Python availability
  check_python_available(python_path)

  # Build command arguments
  args <- c(script_path, docx_path)
  if (!is.null(output)) {
    output <- user_path_prep(output)
    args <- c(args, "-o", output)
  }

  if (!quiet) {
    ui_bullets(c("i" = "Extracting Word document revisions..."))
  }

  # Execute Python script
  result <- system2(
    command = python_path,
    args = args,
    stdout = TRUE,
    stderr = TRUE
  )

  # Check execution results
  exit_status <- attr(result, "status")
  if (!is.null(exit_status) && exit_status != 0) {
    stderr_msg <- paste(result, collapse = "\n")
    if (
      grepl("ModuleNotFoundError", stderr_msg) ||
        grepl("docx2python", stderr_msg)
    ) {
      ui_abort(c(
        "x" = "Python dependency {.pkg docx2python} is not installed.",
        "i" = "Please install it using one of the following commands:",
        " " = "{.code pip install docx2python}",
        " " = "{.code pip3 install docx2python}",
        "i" = "Or use uv: {.code uv pip install docx2python}"
      ))
    }
    ui_abort(c(
      "x" = "Python script execution failed.",
      "i" = "Error message: {stderr_msg}"
    ))
  }

  if (!is.null(output)) {
    if (!quiet) {
      ui_bullets(c("v" = "Revisions saved to {.path {output}}"))
    }
    return(invisible(NULL))
  }

  if (!quiet) {
    ui_bullets(c("v" = "Extraction complete."))
  }
  result
}


#' Get docx2md directory path
#'
#' Finds the docx2md directory containing the Python script and virtual environment.
#' Works both during development (inst/docx2md) and after installation.
#' @noRd
get_docx2md_dir <- function() {
  # Try installed package path first
  docx2md_dir <- tryCatch(
    path_package(package = "acwri", "docx2md"),
    error = function(e) NULL
  )

  if (!is.null(docx2md_dir) && dir_exists(docx2md_dir)) {
    return(docx2md_dir)
  }

  # Development fallback: look relative to the source file location
  # This handles the case when running from source (e.g., devtools::load_all)
  dev_paths <- c(
    # If we're in the package source directory
    "inst/docx2md",
    # Absolute path as last resort
    "/Users/zero/Desktop/zeroverse/easyPKGs/acwri/inst/docx2md"
  )

  for (dev_path in dev_paths) {
    if (dir_exists(dev_path)) {
      return(normalizePath(dev_path, mustWork = FALSE))
    }
  }

  NULL
}


#' Find Python script path
#' @noRd
find_docx_script <- function() {
  docx2md_dir <- get_docx2md_dir()

  if (!is.null(docx2md_dir)) {
    script_path <- path(docx2md_dir, "extract_docx_track_changes.py")
    if (file_exists(script_path)) {
      return(script_path)
    }
  }

  ui_abort(c(
    "x" = "Could not find Python script {.file extract_docx_track_changes.py}",
    "i" = "Please ensure {.pkg acwri} is installed correctly."
  ))
}


#' Find default Python path
#'
#' Returns the Python path from the bundled virtual environment.
#' The .venv is located in the same directory as the Python script.
#' @noRd
find_default_python <- function() {
  docx2md_dir <- get_docx2md_dir()

  if (!is.null(docx2md_dir)) {
    # Try bundled virtual environment
    venv_python <- path(docx2md_dir, ".venv", "bin", "python")
    if (file_exists(venv_python)) {
      return(venv_python)
    }
  }

  # Fall back to system python3
  "python3"
}


#' Check Python availability
#' @noRd
check_python_available <- function(python_path) {
  result <- tryCatch(
    system2(python_path, "--version", stdout = TRUE, stderr = TRUE),
    error = function(e) NULL,
    warning = function(w) NULL
  )

  if (is.null(result)) {
    ui_abort(c(
      "x" = "Could not find Python at {.path {python_path}}",
      "i" = "Please ensure Python is installed, or specify the path via the {.arg python_path} argument.",
      "i" = "Setup instructions can be found in {.path inst/docx2md/README.md}"
    ))
  }
}
