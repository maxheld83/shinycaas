# deploy shiny app using rocker image
az_webapp_config(
  name = "hello-shiny",
  # this image actually includes *more* than necessary
  # for example, it includes shinyserver, but just shiny would suffice
  deployment_container_image_name = "rocker/shiny:4.0.2",
  # above image has no `ENTRYPOINT` and/or `CMD` to start shiny by default.
  # so this `[COMMAND]` must be appended to `docker run`
  startup_file = paste(
    "Rscript ",
    # setting shiny options for azure manually
    # equivalent to running shinycaas::az_webapp_shiny_opts()
    "-e options(shiny.host='0.0.0.0',shiny.port=as.integer(Sys.getenv('PORT')",
    "-e shiny::runExample('01_hello')"
  ),
  # replace below with your own credentials
  plan = "hoad",
  resource_group = "hoad",
  subscription = "f0dd3a37-0a4e-4e7f-9c9b-cb9f60146edc"
)
