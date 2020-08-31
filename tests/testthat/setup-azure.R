# hoad credentials used for testing
# authentication happens outside of r, see github actions main.yaml
plan <- "hoad"
resource_group <- "hoad"
subscription <- "f0dd3a37-0a4e-4e7f-9c9b-cb9f60146edc"

# deploy shiny app using rocker image
az_webapp_config(
  name = "hello-shiny",
  # this image actually includes *more* than necessary
  # for example, it includes shinyserver, but just shiny would suffice
  deployment_container_image_name = "rocker/shiny:4.0.2",
  # above image has no `ENTRYPOINT` and/or `CMD` to start shiny by default.
  # so this `[COMMAND]` must be appended to `docker run`
  startup_file = paste(
    "Rscript",
    # setting shiny options for azure manually
    # equivalent to running shinycaas::az_webapp_shiny_opts()
    "-e options(shiny.host='0.0.0.0',shiny.port=as.integer(Sys.getenv('PORT')))",
    # remove getOption call https://github.com/subugoe/shinycaas/issues/37
    "-e shiny::runExample('01_hello',port=getOption('shiny.port'))"
  ),
  # replace below with your own credentials
  plan = plan,
  resource_group = resource_group,
  subscription = subscription
)

# deploy shiny app to slot
az_webapp_config(
  name = "hello-shiny",
  # this image actually includes *more* than necessary
  # for example, it includes shinyserver, but just shiny would suffice
  deployment_container_image_name = "rocker/shiny:4.0.2",
  # above image has no `ENTRYPOINT` and/or `CMD` to start shiny by default.
  # so this `[COMMAND]` must be appended to `docker run`
  startup_file = paste(
    "Rscript",
    # setting shiny options for azure manually
    # equivalent to running shinycaas::az_webapp_shiny_opts()
    "-e options(shiny.host='0.0.0.0',shiny.port=as.integer(Sys.getenv('PORT')))",
    # remove getOption call https://github.com/subugoe/shinycaas/issues/37
    "-e shiny::runExample('04_mpg',port=getOption('shiny.port'))"
  ),
  # replace below with your own credentials
  plan = plan,
  resource_group = resource_group,
  subscription = subscription,
  slot = "mpg"
)


# below env vars and secrets are only available on github actions
if (is_github_actions()) {
  # deploy shiny app using muggle image
  # for an easier way to set these arguments, see the {muggle} package
  az_webapp_config(
    name = "old-faithful",
    deployment_container_image_name = paste0(
      "docker.pkg.github.com/subugoe/shinycaas/oldfaithful", ":",
      ifelse(is_github_actions(), Sys.getenv("GITHUB_SHA"), "latest")
    ),
    plan = plan,
    resource_group = resource_group,
    subscription = subscription,
    docker_registry_server_url = "https://docker.pkg.github.com",
    docker_registry_server_user = Sys.getenv("GITHUB_ACTOR"),
    docker_registry_server_password = Sys.getenv("GITHUB_TOKEN")
  )
}
