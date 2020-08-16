#' Use `github.sha` environment variable or `"latest"` as docker image tag
#'
#' Retrieves the current git commit SHA from the [`github.sha`](https://docs.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions) environment variable set on GitHub Actions.
#' Returns `latest`, if the environment variable is an empty string.
#' Internal function used to retrieve the appropriate docker image tag for a shiny app.
#'
#' @return character string
#'
#' @export
#'
#' @keywords internal
get_tag <- function() {
  sha <- Sys.getenv("gihub.sha")
  if (sha == "") {
    tag <- "latest"
  } else {
    tag <- sha
  }
  tag
}
