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

# TODO migrate to ghactions repo https://github.com/subugoe/shinycaas/issues/52
#' Get GitHub Actions Environment Variables or Local Equivalent
#'
#' Using [environment variables set on GitHub Actions](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables) *or* their local equivalents can sometimes be useful, for example in testing.
#' When running inside GitHub Actions ([is_github_actions()]), returns the respective environment variable.
#' Otherwise, returns a `local` equivalent or errors out.
#'
#' @param ghactions
#' The [GitHub Actions environment variable](https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables) to get when `is_github_actions() == TRUE`, as a character string.
#'
#' @param local
#' The value to be used when `is_github_actions() == FALSE`.
#'
#' @keywords internal
#'
#' @export
getenv2 <- function(ghactions, local) {
  checkmate::assert_string(ghactions)
  if (is_github_actions()) {
    res <- Sys.getenv(ghactions)
    if (res == "") {
      stop("Environment variable", ghactions, "is empty on GitHub Actions.")
    }
  } else {
    res <- local
    if (res == "") {
      stop("The local equivalent to the", ghactions, "environment variable is empty.")
    }
  }
  res
}
