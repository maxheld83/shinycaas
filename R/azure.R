#' Run a shiny app on [Microsoft Azure Web Apps for Containers](https://azure.microsoft.com/en-us/services/app-service/containers/) (awac)
#'
#' Wraps the [Azure Command-Line Interface (CLI)](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest) with defaults suitable for deploying a shiny app.
#'
#' @param name
#' Name of the web app.
#'
#' @param docker_custom_image_name
#' The container custom image name and optionally the tag name.
#' Must include everything to run the shiny app, including shiny itself.
#' Does not need to include shiny server or other software to route, load balance and serve shiny.
#'
#' @param startup_file
#' Command use as an [`--entrypoint`](https://docs.docker.com/engine/reference/run/#entrypoint-default-command-to-execute-at-runtime).
#'
#' @param subscription
#' Name or ID of the Azure subscription to which costs are billed.
#' According to an upvoted answer on Stack Overflow, [Azure subscription IDs need not be considered a secret or personal identifiable information (PII)](https://stackoverflow.com/questions/45661109/are-azure-subscription-id-aad-tenant-id-and-aad-app-client-id-considered-secre).
#' However, depending your applicable context and policies, you may want to provide this argument as a secret.
#'
#' @param resource_group
#' The [Azure resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal) to which the shiny app should belong.
#'
#' @param docker_registry_server_url
#' The container registry server url.
#'
#' @param docker_registry_server_user
#' The container registry server username.
#'
#' @export
az_webapp_config <- function(name = "hoad",
                             docker_custom_image_name = paste0(
                               "docker.pkg.github.com/subugoe/hoad/hoad-dev",
                               ":",
                               "azure"
                             ),
                             startup_file = "init.sh",
                             subscription = "f0dd3a37-0a4e-4e7f-9c9b-cb9f60146edc",
                             resource_group = "hoad",
                             docker_registry_server_url = "https://docker.pkg.github.com",
                             docker_registry_server_user = "maxheld83") {
  checkmate::assert_string(name)
  checkmate::assert_string(docker_custom_image_name)
  checkmate::assert_string(startup_file)
  checkmate::assert_string(subscription)
  checkmate::assert_string(resource_group)
  checkmate::assert_string(docker_registry_server_url)
  checkmate::assert_string(docker_registry_server_user)


  cli::cli_alert_info("Setting defaults ...")
  az_cli_run(args = c("account", "set", "--subscription", subscription))
  az_cli_run(args = c(
    "configure",
    # only applies to current folder, useful if there are various projects
    "--scope", "local",
    "--defaults", paste0("group=", resource_group), paste0("web=", name)
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
    "--http20-enabled", "false",
    "--startup-file", "init.sh"
  ))

  cli::cli_alert_info("Setting container configuration ...")
  az_cli_run(args = c(
    "webapp", "config", "container", "set",
    "--docker-custom-image-name", docker_custom_image_name,
    "--docker-registry-server-url", docker_registry_server_url,
    "--docker-registry-server-user", docker_registry_server_user,
    "--enable-app-service-storage", "false"
  ))
  # weirdly this cannot be set in the above
  az_cli_run(args = c(
    "webapp", "config", "appsettings", "set",
    "--settings", "DOCKER_ENABLE_CI=false"
  ))

  cli::cli_alert_info("Restaring web app ...")
  # TODO might not be necessary #20
  az_cli_run(args = c(
    "webapp", "restart"
  ))

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
