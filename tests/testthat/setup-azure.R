# hoad credentials used for testing
# authentication happens outside of r, see github actions main.yaml
# during testing .azure/ is not available, so we have to set that here
plan <- "hoad"
resource_group <- "hoad"

# deploy shiny app using rocker image
shiny_deploy_az(
  name = "hello-shiny",
  # this image actually includes *more* than necessary
  # for example, it includes shinyserver, but just shiny would suffice
  deployment_container_image_name = "rocker/shiny:4.0.2",
  # above image has no `ENTRYPOINT` and/or `CMD` to start shiny by default.
  # so this `[COMMAND]` must be appended to `docker run`
  startup_file = paste(
    "Rscript",
    # setting shiny options for azure manually
    # equivalent to running shinycaas::shiny_opts_az()
    "-e options(shiny.host='0.0.0.0',shiny.port=as.integer(Sys.getenv('PORT')))",
    # remove getOption call https://github.com/subugoe/shinycaas/issues/37
    "-e shiny::runExample('01_hello',port=getOption('shiny.port'))"
  ),
  plan = plan,
  resource_group = resource_group
)

# deploy shiny app to slot
shiny_deploy_az(
  name = "hello-shiny",
  deployment_container_image_name = "rocker/shiny:4.0.2",
  startup_file = paste(
    "Rscript",
    "-e options(shiny.host='0.0.0.0',shiny.port=as.integer(Sys.getenv('PORT')))",
    "-e shiny::runExample('04_mpg',port=getOption('shiny.port'))"
  ),
  plan = plan,
  slot = "mpg" # a more suitable slot name might be "dev" or "staging"
)

# below env vars and secrets are only available on github actions
if (is_github_actions()) {
  # deploy shiny app using muggle image
  # for an easier way to set these arguments, see the {muggle} package
  shiny_deploy_az(
    name = "old-faithful",
    deployment_container_image_name = paste0(
      "docker.pkg.github.com/subugoe/shinycaas/oldfaithful", ":",
      ifelse(is_github_actions(), Sys.getenv("GITHUB_SHA"), "latest")
    ),
    plan = plan,
    docker_registry_server_url = "https://docker.pkg.github.com",
    docker_registry_server_user = Sys.getenv("GITHUB_ACTOR"),
    docker_registry_server_password = Sys.getenv("GITHUB_TOKEN")
  )
}
