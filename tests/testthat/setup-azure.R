# deploy shiny app using rocker image
az_webapp_config(
  name = "hello-shiny",
  # this image includes *more* than necessary
  # for example, it includes shinyserver, but just shiny would suffice
  deployment_container_image_name = "rocker/shiny:4.0.2",
  # above image includes no suitable default `RUN`
  # so this `[COMMAND]` must be appended to `docker run`
  startup_file = paste0(
    "Rscript -e ",
    # no more spaces from now on
    "shiny::runExample('01_hello',", # shiny example app
    "host='0.0.0.0',", # necessary to let azure talk to container
    "port=as.integer(Sys.getenv('PORT')))" # env var set by azure
  ),
  # replace below with your own credentials
  plan = "hoad",
  resource_group = "hoad",
  # this is the subugoe subscription used for testing
  subscription = "f0dd3a37-0a4e-4e7f-9c9b-cb9f60146edc"
)
