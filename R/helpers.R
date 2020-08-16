#' Use `github.sha` environment variable or `"latest"` as docker image tag
#'
#' Retrieves the current git commit SHA from the [`GITHUB_SHA`](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables) environment variable set on GitHub Actions.
#' Returns `latest`, if the environment variable is an empty string.
#' Internal function used to retrieve the appropriate docker image tag for a shiny app.
#'
#' @return character string
#'
#' @export
#'
#' @keywords internal
get_tag <- function() {
  sha <- Sys.getenv("GITHUB_SHA")
  if (sha == "") {
    tag <- "latest"
  } else {
    tag <- sha
  }
  tag
}
