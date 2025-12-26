# Project Context

## Purpose

**acwri** (Academic Writing) is an R package that provides tools for academic writing workflows. It integrates various utilities to streamline academic writing tasks for R users, including document setup, formatting, and other helpful functions.

The package was forked from `acwri` and adapted for academic writing purposes. It maintains the robust infrastructure patterns from the original package while focusing on academic-specific functionality.

### Goals
- Provide a cohesive set of tools for academic writing in R
- Simplify common academic document workflows
- Leverage R's ecosystem for reproducible research

## Tech Stack

- **Language**: R (≥ 4.1)
- **Documentation**: roxygen2 with Markdown syntax
- **Testing**: testthat (edition 3, parallel execution enabled)
- **Code Formatting**: Air (tidyverse style)
- **Package Documentation Site**: pkgdown
- **Version Control**: Git
- **CI/CD**: GitHub Actions
- **Package Management**: devtools, pak

### Key Dependencies
- **CLI/UI**: cli, crayon, rlang
- **File System**: fs, rprojroot
- **Git/GitHub**: gert, gh
- **Templates**: whisker, glue
- **Configuration**: yaml, jsonlite
- **Other**: curl, desc, lifecycle, purrr, withr

## Project Conventions

### Code Style

- Follow the [tidyverse style guide](https://style.tidyverse.org)
- Use [Air](https://posit-dev.github.io/air/) for formatting (config in `air.toml`)
- Template files in `inst/templates/` are excluded from formatting
- All user-facing messages use helpers in `utils-ui.R` (see `acwri.quiet` option)
- Use Markdown syntax in roxygen2 documentation

### Architecture Patterns

- **Active Project Pattern**: Many functions operate on an "active project" whose path is stored internally
  - Use `proj_get()` and `proj_set()` to access/modify
  - Form paths to project files with `proj_path()`
  - Get relative paths with `proj_rel_path()`
- **Naming Conventions**:
  - Public functions: `use_*()` functions for setup tasks
  - Internal helpers: Prefixed by feature area (e.g., `git_*()`, `github_*()`)
  - Internal utilities: `utils-*.R` files
- **Path Handling**: All user-provided paths processed with `user_path_prep()`
- **Git Operations**: 
  - Make commits with `git_commit_ask()` (not directly with gert)
  - Use `challenge_uncommitted_changes()` at function start for operations that modify Git state

### Testing Strategy

- **Framework**: testthat (edition 3)
- **Parallel Execution**: Enabled (`Config/testthat/parallel: TRUE`)
- **Test Location**: `tests/testthat/`
- **Test Suppression**: `acwri.quiet` option controls message output
  - Set in `setup.R` / `teardown.R` to suppress output by default
  - Use `withr::local_options(acwri.quiet = FALSE)` for snapshot tests
- **Coverage**: Track with covr + codecov

### Git Workflow

- **Branch Strategy**: Feature branches with PR-based workflow
- **PR Functions**: Use `pr_init()`, `pr_push()`, `pr_fetch()`, etc.
- **Commit Style**: Conventional commits encouraged
- **NEWS Updates**: Add bullets to `NEWS.md` for user-facing changes (follow [tidyverse NEWS style](https://style.tidyverse.org/news.html))

## Domain Context

- **Primary Users**: R users engaged in academic writing and reproducible research
- **Use Cases**: Document setup, project scaffolding, formatting utilities
- **Related Packages**: Original `acwri`, devtools, pkgdown, roxygen2

## Important Constraints

- **R Version**: Requires R ≥ 4.1
- **License**: MIT
- **Lifecycle**: Experimental stage
- **GitHub Repository**: jixing475/acwri
- **Legacy Note**: Contains legacy `ui_*()` functions (superseded, kept for compatibility)

## External Dependencies

- **GitHub API**: Via `gh` package for GitHub interactions
- **Git**: Via `gert` package for Git operations
- **RStudio API**: Optional integration via `rstudioapi`
- **Quarto**: Optional suggestion for advanced document workflows
