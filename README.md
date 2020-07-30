
# shinycaas

<!-- badges: start -->
[![Main](https://github.com/subugoe/shinycaas/workflows/.github/workflows/main.yaml/badge.svg)](https://github.com/subugoe/shinycaas/actions)
[![Codecov test coverage](https://codecov.io/gh/subugoe/shinycaas/branch/master/graph/badge.svg)](https://codecov.io/gh/subugoe/shinycaas?branch=master)
[![R build status](https://github.com/subugoe/shinycaas/workflows/R-CMD-check/badge.svg)](https://github.com/subugoe/shinycaas/actions)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

The goal of shinycaas is to ...

## Installation

You can install the released version of shinycaas from [CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("shinycaas")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(shinycaas)
## basic example code
```

## System Requirements

This package calls the [Microsoft Azure}(https://azure.microsoft.com/) Command-Line Interface (CLI).
To deploy to Azure, you need to [install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) any machine from which you want to deploy your shiny app.
There's no need to install the Azure CLI into your *production* image; you only need it at deploy time.
If you only deploy from GitHub Actions (recommended) you do not need to install anything; the Azure CLI is [included](https://docs.github.com/en/actions/reference/software-installed-on-github-hosted-runners) in all GitHub-hosted runners.


### Limitations of [shinyapps.io](https://www.shinyapps.io)

- No reproducible environment.
    Deployment to shinyapps.io happens via rsconnect::deployApp(), which in turn relies on some dark {packrat}/{renv} magic.
    The compute environment on shinyapps.io is somewhat undocumented / irreproducible (which R version? which ubuntu? which dependencies?), and rsconnect::deployApp() kind of throws out all the work we've put into our reproducible environment.
- There is no good way to use/store secrets in shinyapps.io (such as for using some API), i.e. no facility to store encrypted secrets, as is common for other PaaS products.
    The only way would be to include secrets in plain the source code.
    The code should, in principle, be available only to us (= people with privileges on shinyapps.io), but is in general not recommended to store secrets in unencrypted form.)
