#' Deploy a shiny app to Azure
#' @example tests/testthat/setup-azure.R
#' @export
#' @name az_webapp
AzureAppService::az_webapp

#' Set Azure defaults
#' @export
#' @name az_configure
AzureAppService::az_configure


# helpers ====

#' Shiny options for Azure
#'
#' Set shiny options as [required for an Azure Webapp](https://docs.microsoft.com/en-us/azure/app-service/containers/configure-custom-container):
#' - `options(shiny.port = as.integer(Sys.getenv('PORT'))`.
#'    Your custom container is expected to listen on `PORT`, an environment variable set by Azure.
#'    If your image suggests `EXPOSE`d ports, that may be respected by Azure (undocumented behavior).
#' - `options(shiny.host = "0.0.0.0")` to make your shiny application accessable to the Azure Webapp hosting environment.
#'
#' @family azure functions
#'
#' @export
shiny_opts_az <- function() {
  port <- Sys.getenv("PORT")
  if (port == "") {
    cli::cli_alert_warning(c(
      "Could not find environment variable {.envvar PORT}. ",
      "Perhaps this is running outside of Azure? ",
      "Reverting to shiny default. "
    ))
    port <- NULL
  } else {
    port <- as.integer(port)
  }
  old_opts <- options(
    shiny.port = port, # defined on azure
    shiny.host = "0.0.0.0" # to give azure access to inner container
  )
  # TODO might revert back to old_opts with
  # withr::defer(options(old_opts), envir = parent.frame(2))
}
