test_that("is_github_enterprise() identifies GitHub Enterprise URLs (or not)", {
  # https://github.com/jixing475/acwri/pull/2098
  expect_true(is_github_enterprise("https://my-cool-org.ghe.com"))

  # not handled yet: self-hosted GHE server
  # https://github.com/jixing475/acwri/pull/2098
  expect_false(is_github_enterprise(
    "https://ghe-gsk-prod.metworx.com/account/reponame"
  ))
})
