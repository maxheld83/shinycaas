#' Determine if code is running inside GitHub Actions
#'
#' Looks for the `GITHUB_ACTIONS` environment variable, as [documented](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables)
#'
#' @noRd
# duplicate from muggle, but better than importing all of muggle
is_github_actions <- function() {
  Sys.getenv("GITHUB_ACTIONS") == "true"
}
