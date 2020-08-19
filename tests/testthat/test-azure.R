test_that("multiplication works", {
  skip_if_not(
    condition = is_github_actions(),
    message = "Only running deployment test on GitHub Actions."
  )
  # TODO test here whether new app actually runs #22
  # must wait for successful redeploy from helper #29
  expect_equal(2 * 2, 4)
})
