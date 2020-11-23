
# shinycaas

<!-- badges: start -->
[![Main](https://github.com/subugoe/shinycaas/workflows/.github/workflows/main.yaml/badge.svg)](https://github.com/subugoe/shinycaas/actions)
[![Codecov test coverage](https://codecov.io/gh/subugoe/shinycaas/branch/master/graph/badge.svg)](https://codecov.io/gh/subugoe/shinycaas?branch=master)
[![CRAN status](https://www.r-pkg.org/badges/version/shinycaas)](https://CRAN.R-project.org/package=shinycaas)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

The goal of shinycaas is to make it easy to deploy shiny apps to Container-as-a-Service (CaaS) products in the public cloud.

### Limitations of [shinyapps.io](https://www.shinyapps.io)

- No reproducible environment.
    Deployment to shinyapps.io happens via rsconnect::deployApp(), which in turn relies on some dark {packrat}/{renv} magic.
    The compute environment on shinyapps.io is somewhat undocumented / irreproducible (which R version? which ubuntu? which dependencies?), and rsconnect::deployApp() kind of throws out all the work we've put into our reproducible environment.
- There is no good way to use/store secrets in shinyapps.io (such as for using some API), i.e. no facility to store encrypted secrets, as is common for other PaaS products.
    The only way would be to include secrets in plain the source code.
    The code should, in principle, be available only to us (= people with privileges on shinyapps.io), but is in general not recommended to store secrets in unencrypted form.)
