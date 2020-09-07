context("azure")

# wrap all
test_that("deployment works", {
  expect_equal(1, 1)
})

# az account
test_that("az account works", {
  checkmate::expect_subset(
    x = "subugoe",
    choices = az_account()$name,
    empty.ok = FALSE
  )
})

# az configure
test_that("az configure works", {
  old_defaults <- az_configure_list()
  expect_identical(
    az_configure(name = "foo", resource_group = "bar"),
    list(resource_group = "bar", name = "foo")
  )
  expect_identical(
    az_configure_list(),
    list(resource_group = "bar", name = "foo")
  )
  fs::file_delete(".azure/config")
  # this does not appear to work
  # expect_error(az_configure())
  withr::defer(do.call(az_configure, old_defaults))
})

# az webapp
test_that("az webapp create works", {
  expect_identical(1, 1)
})

# helpers
test_that("cli commands work", {
  checkmate::expect_list(az_cli_run(cmd = "version", opt = "--verbose"))
})
