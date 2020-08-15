#' Deploy a shiny app to [Microsoft Azure Web Apps for Containers](https://azure.microsoft.com/en-us/services/app-service/containers/)
#'
#' Wraps the [Azure Command-Line Interface (CLI)](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) with defaults suitable for deploying a shiny app.
#'
#' @param name
#' Name of the web app.
#'
#' @param deployment_container_image_name
#' The custom image name and optionally the tag name.
#' Image must
#' - include everything needed to run the shiny app, including shiny itself,
#'   but *does not* need to include shiny server or other software to route, load balance and serve shiny,
#' - include an `ENTRYPOINT` and/or [`CMD`](https://docs.docker.com/engine/reference/builder/#cmd) instruction to start shiny automatically (recommended), *or* shiny must be started via the `startup_file` argument.
#'
#' @param startup_file
#' `docker run` [`[COMMAND]`](https://docs.docker.com/engine/reference/run/) to use inside of your custom image `deployment_container_image_name`.
#' Defaults to `NULL`, in which case the container is expected to start up shiny automatically (recommended).
#' For details on the shiny startup command, see the examples.
#'
#' **The `[EXPR]` (anything after `-e`) must not be quoted, and must not contain spaces ([#27](https://github.com/subugoe/shinycaas/issues/27))**.
#' For example, the following `startup-file`s are valid (if nonsensical, because they don't start a shiny app)
#' - `"Rscript -e 1+1"` (no spaces)
#' - `"Rscript -e print('foo')"` (no spaces, no quoting *of* the `[EXPR]`)
#'
#' The following `startup-file`s are *invalid*:
#' - `"Rscript -e 1 + 1"` (spaces inside `[EXPR]`)
#' - `"Rscript -e '1+1'"` (quoting of `[EXPR]` would be treated as `"Rscript -e '\"1+1\"'"`).
#'
#' @param plan
#' Name or resource id of the app service plan.
#'
#' @param resource_group
#' The [Azure resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal) to which the shiny app should belong.
#'
#' @param subscription
#' Name or ID of the Azure subscription to which costs are billed.
#' According to an upvoted answer on Stack Overflow, [Azure subscription IDs need not be considered a secret or personal identifiable information (PII)](https://stackoverflow.com/questions/45661109/are-azure-subscription-id-aad-tenant-id-and-aad-app-client-id-considered-secre).
#' However, depending your applicable context and policies, you may want to provide this argument as a secret.
#'
#' @param docker_registry_server_url
#' The container registry server url.
#' Defaults to `NULL`, in which case the azure default, [docker hub](http://hub.docker.com) is used.
#'
#' @param docker_registry_server_user,docker_registry_server_password
#' Credentials for private container registries.
#' Defaults to `NULL` for public registries.
#' Do not expose your credentials in public code; it's best to use secret environment variables.
#'
#' @param restart whether to restart the web app.
#'
#' @example tests/testthat/setup-azure.R
#'
#' @export
az_webapp_config <- function(name,
                             deployment_container_image_name,
                             startup_file = NULL,
                             plan,
                             resource_group,
                             subscription,
                             docker_registry_server_url = NULL,
                             docker_registry_server_user = NULL,
                             docker_registry_server_password = NULL,
                             restart = FALSE) {
  checkmate::assert_string(name)
  checkmate::assert_string(deployment_container_image_name)
  checkmate::assert_string(startup_file, )
  checkmate::assert_string(subscription)
  checkmate::assert_string(resource_group)
  checkmate::assert_string(docker_registry_server_url, null.ok = TRUE)
  checkmate::assert_string(docker_registry_server_user, null.ok = TRUE)
  checkmate::assert_string(docker_registry_server_password, null.ok = TRUE)

  cli::cli_alert_info("Setting defaults ...")
  # unclear where those are set
  az_cli_run(args = c("account", "set", "--subscription", subscription))
  # precaution against ambiguous credentials and later cleanup deletion
  if (fs::dir_exists(".azure")) {
    usethis::ui_stop(
      "There is a folder {usethis::ui_path('.azure')} at the working directory.
      It may already contain defaults.
      Delete it to proceed."
    )
  }
  az_cli_run(args = c(
    "configure",
    # only applies to current folder, useful if there are various projects
    "--scope", "local",
    "--defaults", paste0("group=", resource_group), paste0("web=", name)
  ))
  # clean up not to let defaults linger
  withr::defer(fs::dir_delete(".azure"))

  cli::cli_alert_info("Creating or updating web app ...")
  az_cli_run(args = c(
    "webapp", "create",
    "--name", name,
    "--plan", plan,
    "--deployment-container-image-name", deployment_container_image_name,
    if (!is.null(docker_registry_server_url)) {
      c("--docker-registry-server-url", docker_registry_server_url)
    },
    if (!is.null(docker_registry_server_user)) {
      c("--docker-registry-server-user", docker_registry_server_user)
    },
    if (!is.null(docker_registry_server_password)) {
      c("--docker-registry-server-password", docker_registry_server_password)
    },
    if (!is.null(startup_file)) {
      c("--startup-file", startup_file)
    }
    # todo also pass on tags #25
  ))

  cli::cli_alert_info("Setting web app tags ...")
  # for some reason, this is not part of the webapp config, though it is on portal.azure.com
  az_cli_run(args = c(
    "webapp", "update",
    "--client-affinity-enabled", "true", # send traffic to same machine
    "--https-only", "false" # TODO #3
  ))

  cli::cli_alert_info("Setting web app configuration ...")
  az_cli_run(args = c(
    "webapp", "config", "set",
    "--always-on", "true",
    "--ftps-state", "disabled", # not needed
    "--web-sockets-enabled", "true", # needed to serve shiny
    "--http20-enabled", "false"
  ))

  # weirdly this cannot be set in the above
  az_cli_run(args = c(
    "webapp", "config", "appsettings", "set",
    "--settings", "DOCKER_ENABLE_CI=false"
  ))

  cli::cli_alert_info("Restaring web app ...")
  if (restart) {
    az_cli_run(args = c(
      "webapp", "restart"
    ))
  }

  # TODO check whether app actually runs #22
}

#' Run Azure CLI
#'
#' @inheritDotParams processx::run
#'
#' @keywords internal
az_cli_run <- function(...) {
  processx::run(
    command = "az",
    echo_cmd = TRUE,
    spinner = TRUE,
    echo = TRUE,
    ...
  )
}

#' @describeIn az_webapp_config
#' Set shiny options as [required for an Azure Webapp](https://docs.microsoft.com/en-us/azure/app-service/containers/configure-custom-container):
#' - `options(shiny.port = as.integer(Sys.getenv('PORT'))`.
#'    Your custom container is expected to listen on `PORT`, an environment variable set by Azure.
#'    If your image suggests `EXPOSE`d ports, that may be respected by Azure (undocumented behavior).
#' - `options(shiny.host = "0.0.0.0")` to make your shiny application accessable to the Azure Webapp hosting environment.
#'
#' You can also set these options manually as in the below example.
#'
#' @export
az_webapp_shiny_opts <- function() {
  port <- Sys.getenv("PORT")
  if (port == "") {
    cli::cli_alert_warning(
      "Could not find environment variable {cli::cli_code('PORT')}.",
      "Perhaps this is running outside of Azure?",
      "Reverting to shiny default."
    )
    port <- NULL
  } else {
    port <- as.integer(port)
  }
  old_opts <- options(
    shiny.port = port, # defined on azure
    shiny.host = "0.0.0.0" # to five azure access to inner container
  )
  # TODO might revert back to old_opts with
  # withr::defer(options(old_opts), envir = parent.frame(2))
}
