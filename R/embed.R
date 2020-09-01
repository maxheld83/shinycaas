#' Embed a shiny app in a pkgdown site
#'
#' Embeds a shiny app in a pkgdown, or similar bootstrap website.
#' Does not offer a print method for non-html output.
#'
#' @param src The URL of the shiny app to embed.
#' @param name Name of the iframe.
#' @param height,width The dimensions of the iframe as CSS units.
#'
#' @return A tag list as from [htmltools::tagList()].
#'
#' @family helper functions
#'
#' @export
include_app2 <- function(src, name = NULL, height = "100%", width = "100%") {
  htmltools::tags$div(
    htmltools::tags$iframe(
      src = src,
      height = height,
      width = width,
      name = name
    ),
    class = "shiny-embed-pkgdown",
    htmltools::htmlDependency(
      name = "shinycaas",
      version = utils::packageVersion("shinycaas"),
      src = system.file("css", package = "shinycaas"),
      stylesheet = "embed_pkgdown.css"
    )
  )
}
