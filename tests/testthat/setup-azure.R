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

# deploy shiny app using muggle image
# for an easier way to set these arguments, see the {muggle} package
az_webapp_config(
  name = "old-faithful",
  deployment_container_image_name = paste0(
    "docker.pkg.github.com/subugoe/shinycaas/oldfaithful", ":",
    ifelse(Sys.getenv("GITHUB_SHA") == "", "latest", Sys.getenv("GITHUB_SHA"))
  ),
  plan = plan,
  resource_group = resource_group,
  subscription = subscription,
  docker_registry_server_url = "https://docker.pkg.github.com",
  docker_registry_server_user = "maxheld83"
  # docker password is a GITHUB PAT, pasted directly into portal.azure.com
)
