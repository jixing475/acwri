# Branch ------------------------------------------------------------------
test_that("git_branch() works", {
  skip_if_no_git_user()
  create_local_project()

  expect_acwri_error(git_branch(), "Cannot detect")

  git_init()
  expect_acwri_error(git_branch(), "unborn branch")

  writeLines("blah", proj_path("blah.txt"))
  gert::git_add("blah.txt", repo = git_repo())
  gert::git_commit("Make one commit", repo = git_repo())
  # branch name can depend on user's config, e.g. could be 'master' or 'main'
  expect_no_error(
    b <- git_branch()
  )
  expect_true(nzchar(b))
})

# Protocol ------------------------------------------------------------------
test_that("git_protocol() catches bad input from acwri.protocol option", {
  withr::with_options(
    list(acwri.protocol = "nope"),
    {
      expect_acwri_error(git_protocol(), "must be either")
      expect_null(getOption("acwri.protocol"))
    }
  )
  withr::with_options(
    list(acwri.protocol = c("ssh", "https")),
    {
      expect_acwri_error(git_protocol(), "must be either")
      expect_null(getOption("acwri.protocol"))
    }
  )
})

test_that("use_git_protocol() errors for bad input", {
  expect_acwri_error(use_git_protocol("nope"), "must be either")
})

test_that("git_protocol() defaults to 'https'", {
  withr::with_options(
    list(acwri.protocol = NULL),
    expect_identical(git_protocol(), "https")
  )
})

test_that("git_protocol() honors, vets, and lowercases the option", {
  withr::with_options(
    list(acwri.protocol = "ssh"),
    expect_identical(git_protocol(), "ssh")
  )
  withr::with_options(
    list(acwri.protocol = "SSH"),
    expect_identical(git_protocol(), "ssh")
  )
  withr::with_options(
    list(acwri.protocol = "https"),
    expect_identical(git_protocol(), "https")
  )
  withr::with_options(
    list(acwri.protocol = "nope"),
    expect_acwri_error(git_protocol(), "must be either")
  )
})

test_that("use_git_protocol() prioritizes and lowercases direct input", {
  withr::with_options(
    list(acwri.protocol = "ssh"),
    {
      expect_identical(use_git_protocol("HTTPS"), "https")
      expect_identical(git_protocol(), "https")
    }
  )
})
