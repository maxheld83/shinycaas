empty_envvar <- "FOOBARZAP123"
test_that("getenv2 works locally", {
  skip_on_ci()
  expect_error(getenv2(
    ghactions = empty_envvar,
    local = Sys.getenv(empty_envvar) # likely empty
  ))
  expect_equal(
    getenv2(ghactions = empty_envvar, local = "bingo"),
    "bingo"
  )
})
test_that("getenv2 works on github actions", {
  skip_if_not(
    is_github_actions(),
    message = "Not running on GitHub Actions"
  )
  expect_error(getenv2(
    ghactions = empty_envvar,
    local = Sys.getenv(empty_envvar) # likely empty
  ))
  expect_equal(
    getenv2(ghactions = "GITHUB_SERVER_URL", local = "bingo"),
    "https://github.com"
  )
})
