test_that("sets version for imports & depends dependencies", {
  skip_if_offline()
  withr::local_options(list(repos = c(CRAN = "https://cloud.r-project.org")))

  create_local_package()
  use_package("rlang")
  use_package("desc", "Depends")
  use_latest_dependencies()

  deps <- proj_deps()
  expect_equal(
    deps$version[deps$package %in% c("rlang", "desc")] == "*",
    c(FALSE, FALSE)
  )
})

test_that("doesn't affect suggests", {
  skip_if_offline()
  withr::local_options(list(repos = c(CRAN = "https://cloud.r-project.org")))

  create_local_package()
  use_package("cli", "Suggests")
  use_latest_dependencies()

  deps <- proj_deps()
  expect_equal(deps$version[deps$package == "cli"], "*")
})

test_that("does nothing for a base package", {
  skip_if_offline()
  withr::local_options(list(repos = c(CRAN = "https://cloud.r-project.org")))

  create_local_package()
  use_package("tools")
  # if acwri ever depends on a recommended package, we could test that here too
  use_latest_dependencies()

  deps <- proj_deps()
  expect_equal(deps$version[deps$package == "tools"], "*")
})
