#' Determine if code is running inside GitHub Actions
#'
#' Looks for the `GITHUB_ACTIONS` environment variable, as [documented](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables)
#'
#' @keywords internal
#'
#' @export
# duplicate from muggle, but better than importing all of muggle
is_github_actions <- function() {
  Sys.getenv("GITHUB_ACTIONS") == "true"
}

#' SHA at build time
#'
#' Used for testing.
#' Because package is installed with remotes::install_local() on GitHub Actions, no other source of the commit at *runtime* inside
#'
#' @keywords internal
#'
#' @export
buildtime_sha <- {
  if (is_github_actions()) Sys.getenv("GITHUB_SHA") else "HEAD"
}
