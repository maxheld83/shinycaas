# wrap all ====
#' Deploy a shiny app to Azure
#'
#' Calls the  with defaults suitable for deploying a shiny app.
#' Wraps several steps.
#'
#' @inheritDotParams az_account
#' @inheritDotParams az_configure
#' @inheritDotParams az_webapp
#' @inheritDotParams az_webapp_create
#' @inheritDotParams az_webapp_config_container_set
#'
#' @example tests/testthat/setup-azure.R
#'
#' @template azure
#'
#' @export
shiny_deploy_az <- function(...) {
  az_account(...)
  az_configure(...)
  az_webapp(...)
}

# az login ====
#' Log in to Azure
#'
#' Helper for interactive login.
#' Do not script this function unless you know what you are doing.
#'
#' @template azure
#'
#' @export
az_login <- function(...) {
  az_cli_run(
    cmd = "login",
    ...
  )
}

# az account ====
#' Manage Azure subscription information
#'
#' Subscription defaults to `NULL`, in which case the subscription is expected to be enabled in the azure CLI cache already.
#' Appends `subscription`, if provided.
#' Errors out if no subscription is enabled.
#'
#' @inheritDotParams az_cli_run
#' @template azure
#'
#' @export
az_account <- function(subscription = NULL, ...) {
  if (!is.null(subscription)) {
    az_account_set(subscription = subscription, ...)
  }
  res <- az_account_list(...)
  if (length(res) == 0) {
    stop("There are no enabled subscriptions.")
  }
  cli::cli_alert_info(
    "Found enabled subscription{?s} named {.field {res$name}}."
  )
  res
}

#' @describeIn az_account Get a list of subscriptions for the logged in account.
az_account_list <- function(...) {
  az_cli_run(cmd = c("account", "list"), ...)
}

#' @describeIn az_account Set a subscription to be the current active subscription.
#'
#' @details
#' Subscriptions are kept in the local azure CLI cache, so you should not have to run this more than once.
#' On GitHub Actions, [the azure login action](https://github.com/azure/login) will already set up a subscription.
#'
#' @param subscription
#' Name or ID of the Azure subscription to which costs are billed.
#' According to an upvoted answer on Stack Overflow, [Azure subscription IDs need not be considered a secret or personal identifiable information (PII)](https://stackoverflow.com/questions/45661109/are-azure-subscription-id-aad-tenant-id-and-aad-app-client-id-considered-secre).
#' However, depending your applicable context and policies, you may want to provide this argument as a secret.
#'
#' To find out which subscriptions you are currently authorised to use, run `print(az_account_list())`.
az_account_set <- function(subscription, ...) {
  checkmate::assert_string(subscription)
  cli::cli_alert_info("Setting subscription ...")
  az_cli_run(
    cmd = c("account", "set"),
    req = c("--subscription", subscription),
    ...
  )
}

# az configure ====
#' Manage Azure CLI configuration
#'
#' Overwrites defaults for the Azure CLI to `.azure/` directory (**side effect**), if arguments are provided.
#' Errors out if a default is missing.
#'
#' @details
#' Because of an apparent [bug](https://github.com/Azure/azure-cli/issues/15014), the Azure CLI will always include defaults at `~/.azure/`.
#' These hidden defaults can interfere with these functions.
#' Make sure that you have no default `name` and `resource_group` in the global azure default config in your `HOME` directory.
#'
#' @param name
#' Name of the web app.
#' (In the Azure CLI, this argument is sometimes known as `name`, and sometimes as `web`).
#'
#' @param resource_group
#' The [Azure resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal) to which the shiny app should belong.
#'
#' @inheritDotParams az_cli_run
#' @template azure
#'
#' @export
az_configure <- function(name = NULL, resource_group = NULL, ...) {
  is_changed <- FALSE
  if (!is.null(name)) {
    az_cli_run(
      cmd = "configure",
      opt = c(
        # only applies to current folder, useful if there are various projects
        "--scope", "local",
        "--defaults", paste0("web=", name)
      ),
      ...
    )
    is_changed <- TRUE
  }
  if (!is.null(resource_group)) {
    az_cli_run(
      cmd = "configure",
      opt = c(
        # only applies to current folder, useful if there are various projects
        "--scope", "local",
        "--defaults", paste0("group=", resource_group)
      ),
      ...
    )
    is_changed <- TRUE
  }
  if (is_changed) {
    cli::cli_alert_info(
      "Wrote defaults to {.file .azure/} at the working directory."
    )
  }
  res <- az_configure_list(...)
  if (is.null(res$resource_group)) {
    stop("No resource group provided.")
  }
  # not quite strict/consistent, but it makes life easier of no name is allowed
  cli::cli_alert_success(
    "Using resource group {res$resource_group} and name {res$name} ..."
  )
  res
}

#' @describeIn az_configure List defaults
az_configure_list <- function(...) {
  output <- list(
    resource_group = NULL,
    name = NULL
  )
  res <- az_cli_run(
    cmd = "configure",
    opt = c(
      "--list-defaults", "true",
      # only applies to current folder, useful if there are various projects
      "--scope", "local"
    ),
    ...
  )
  if (length(res) == 0) {
    return(output)
  }
  if (checkmate::test_string(res[res$name == "group", "value"], min.chars = 1)) {
    output$resource_group <- res[res$name == "group", "value"]
  }
  if (checkmate::test_string(res[res$name == "web", "value"], min.chars = 1)) {
    output$name <- res[res$name == "web", "value"]
  }
  output
}

# az_webapp ====
#' Manage web apps
#'
#' @param restart whether to restart the web app.
#'
#' @inheritParams az_account_set
#' @inheritDotParams az_cli_run
#'
#' @template azure
#' @export
az_webapp <- function(slot = NULL, restart = TRUE,
                      ...) {
  checkmate::assert_flag(restart)
  az_webapp_create(...)
  if (!is.null(slot)) az_webapp_deployment_slot_create(slot = slot, ...)
  az_webapp_config_container_set(slot = slot, ...)
  az_webapp_update(slot = slot, ...)
  az_webapp_config_set(slot = slot, ...)
  az_webapp_config_appsettings_set(slot = slot, ...)
  if (restart) az_webapp_restart(slot = slot, ...)
}

#' @describeIn az_webapp Create a web app
#'
#' @inheritParams az_configure
#'
#' @param plan
#' Name or resource id of the app service plan.
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
az_webapp_create <- function(name = NULL,
                             plan,
                             resource_group = NULL,
                             deployment_container_image_name,
                             startup_file = NULL,
                             subscription = NULL,
                             ...) {
  checkmate::assert_string(name, null.ok = TRUE)
  checkmate::assert_string(plan, null.ok = FALSE)
  checkmate::assert_string(resource_group, null.ok = TRUE)
  checkmate::assert_string(deployment_container_image_name, null.ok = FALSE)
  checkmate::assert_string(startup_file, null.ok = TRUE)
  cli::cli_alert_info("Creating or updating web app ...")
  az_cli_run(
    cmd = c("webapp", "create"),
    req = c(
      if (!is.null(name)) c("--name", name),
      "--plan", plan,
      if (!is.null(resource_group)) c("--resource-group", resource_group)
    ),
    opt = c(
      # az webapp create, though undocumented, requires either an image name or a runtime
      # other container settings are set below
      "--deployment-container-image-name", deployment_container_image_name,
      if (!is.null(startup_file)) c("--startup-file", startup_file),
      if (!is.null(subscription)) c("--subscription", subscription)
      # todo also pass on tags #25
    ),
    ...
  )
}

#' @describeIn az_webapp Delete a web app
az_webapp_delete <- function(name = NULL, slot = NULL, ...) {
  az_cli_run(
    cmd = c("webapp", "delete"),
    opt = c(
      if (!is.null(name)) c("--name", name),
      if (!is.null(slot)) c("--slot", slot)
    ),
    ...
  )
}

#' @describeIn az_webapp List web apps
az_webapp_list <- function(...) {
  az_cli_run(cmd = c("webapp", "list"), ...)
}

#' @describeIn az_webapp Gets the details of a web app
az_webapp_show <- function(slot = NULL, ...) {
  az_cli_run(
    cmd = c("webapp", "show"),
    opt = c(
      if (!is.null(slot)) c("--slot", slot)
    ),
    ...
  )
}

#' @describeIn az_webapp Create a deployment slot
#'
#' @param slot
#' The name of the [deployment slot](https://docs.microsoft.com/en-us/azure/app-service/deploy-staging-slots).
#' Defaults to the production slot if not specified.
#' Only available for higher app service plan tiers.
az_webapp_deployment_slot_create <- function(name = NULL,
                                             resource_group = NULL,
                                             slot,
                                             ...) {
  checkmate::assert_string(slot, null.ok = FALSE)
  cli::cli_alert_info("Creating deployment slot ...")
  az_cli_run(
    cmd = c("webapp", "deployment", "slot", "create"),
    req = c(
      if (!is.null(name)) c("--name", name),
      if (!is.null(resource_group)) c("--resource-group", resource_group),
      "--slot", slot
    ),
    ...
  )
}

#' @describeIn az_webapp Set a web app container's settings
#'
#' @param deployment_container_image_name
#' The custom image name and optionally the tag name.
#' Image must
#' - include everything needed to run the shiny app, including shiny itself,
#'   but *does not* need to include shiny server or other software to route, load balance and serve shiny,
#' - include an `ENTRYPOINT` and/or [`CMD`](https://docs.docker.com/engine/reference/builder/#cmd) instruction to start shiny automatically (recommended), *or* shiny must be started via the `startup_file` argument.
#'
#' @param docker_registry_server_url
#' The container registry server url.
#' Defaults to `NULL`, in which case the azure default, [docker hub](http://hub.docker.com) is used.
#'
#' @param docker_registry_server_user,docker_registry_server_password
#' Credentials for private container registries.
#' Defaults to `NULL` for public registries.
#' Do not expose your credentials in public code; it's best to use secret environment variables.
az_webapp_config_container_set <- function(deployment_container_image_name,
                                           docker_registry_server_url = NULL,
                                           docker_registry_server_user = NULL,
                                           docker_registry_server_password = NULL,
                                           slot = NULL,
                                           ...) {
  checkmate::assert_string(deployment_container_image_name)
  checkmate::assert_string(docker_registry_server_url, null.ok = TRUE)
  checkmate::assert_string(docker_registry_server_user, null.ok = TRUE)
  checkmate::assert_string(docker_registry_server_password, null.ok = TRUE)
  cli::cli_alert_info("Setting web app container settings ...")
  az_cli_run(
    cmd = c("webapp", "config", "container", "set"),
    opt = c(
      # redundant, container is already set above, but safer\
      # otherwise command might be called with no args
      "--docker-custom-image-name", deployment_container_image_name,
      if (!is.null(docker_registry_server_url)) {
        c("--docker-registry-server-url", docker_registry_server_url)
      },
      if (!is.null(docker_registry_server_user)) {
        c("--docker-registry-server-user", docker_registry_server_user)
      },
      if (!is.null(docker_registry_server_password)) {
        c("--docker-registry-server-password", docker_registry_server_password)
      },
      if (!is.null(slot)) c("--slot", slot)
    ),
    ...
  )
}

#' @describeIn az_webapp Update a web app
az_webapp_update <- function(slot = NULL, ...) {
  cli::cli_alert_info("Setting web app tags ...")
  # for some reason, this is not part of the webapp config, though it is on portal.azure.com
  az_cli_run(
    cmd = c("webapp", "update"),
    opt = c(
      "--client-affinity-enabled", "true", # send traffic to same machine
      "--https-only", "true",
      if (!is.null(slot)) {
        c("--slot", slot)
      }
    ),
    ...
  )
}

#' @describeIn az_webapp Set a web app's configuration
az_webapp_config_set <- function(slot = NULL, ...) {
  cli::cli_alert_info("Setting web app configuration ...")
  az_cli_run(
    cmd = c("webapp", "config", "set"),
    opt = c(
      "--always-on", "true",
      "--ftps-state", "disabled", # not needed
      "--web-sockets-enabled", "true", # needed to serve shiny
      "--http20-enabled", "true",
      "--min-tls-version", "1.2",
      if (!is.null(slot)) c("--slot", slot)
    ),
    ...
  )
}

#' @describeIn az_webapp Get details of a web app container's settings
az_webapp_config_container_show <- function(slot = NULL, ...) {
  az_cli_run(
    cmd = c("webapp", "config", "container", "show"),
    opt = c(if (!is.null(slot)) c("--slot", slot)),
    ...
  )
}

#' @describeIn az_webapp Set a web app's settings
az_webapp_config_appsettings_set <- function(slot = NULL, ...) {
  # weirdly this cannot be set in the above
  az_cli_run(
    cmd = c("webapp", "config", "appsettings", "set"),
    opt = c(
      "--settings", "DOCKER_ENABLE_CI=false",
      if (!is.null(slot)) c("--slot", slot)
    ),
    ...
  )
}

#' @describeIn az_webapp Restarts the web app
az_webapp_restart <- function(slot = NULL, ...) {
  cli::cli_alert_info("Restaring web app ...")
  az_cli_run(
    cmd = c("webapp", "restart"),
    opt = c(if (!is.null(slot)) c("--slot", slot)),
    ...
  )
}


# helpers ====

#' Run Azure CLI
#' Wraps the [Azure Command-Line Interface (CLI)](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest).
#' @param cmd,req,opt,add
#' Command, required, optional, additional parameters, as for [processx::run()]
#' `add` parameters are reserved for the user to pass down additional arguments.
#' @inheritParams processx::run
#' @return (invisible) `stdout` parsed through [jsonlite::fromJSON()]
#' @family azure functions
#' @export
az_cli_run <- function(cmd,
                       req = NULL,
                       opt = NULL,
                       add = NULL,
                       echo_cmd = FALSE,
                       echo = FALSE,
                       ...) {
  res <- processx::run(
    command = "az",
    # redudantly setting json output to be safe; this is expected below
    args = c(cmd, req, opt, "--output", "json", add),
    echo_cmd = echo_cmd,
    spinner = TRUE,
    echo = echo
  )
  if (res$stdout == "") {
    # some az commands return nothing, so we have to protect against that
    return(NULL)
  }
  invisible(jsonlite::fromJSON(res$stdout))
}

#' Shiny options for Azure
#'
#' Set shiny options as [required for an Azure Webapp](https://docs.microsoft.com/en-us/azure/app-service/containers/configure-custom-container):
#' - `options(shiny.port = as.integer(Sys.getenv('PORT'))`.
#'    Your custom container is expected to listen on `PORT`, an environment variable set by Azure.
#'    If your image suggests `EXPOSE`d ports, that may be respected by Azure (undocumented behavior).
#' - `options(shiny.host = "0.0.0.0")` to make your shiny application accessable to the Azure Webapp hosting environment.
#'
#' You can also set these options manually, see [az_webapp()].
#'
#' @family azure functions
#'
#' @export
shiny_opts_az <- function() {
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

#' Embed a shiny app hosted on Azure
#'
#' @inheritDotParams include_app2
#'
#' @inheritParams az_webapp
#'
#' @family azure functions
#'
#' @export
include_app2_az <- function(slot = NULL, ...) {
  NULL
}
