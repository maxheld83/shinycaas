FROM subugoe/muggle-onbuild:2e75e10fc82b4c5cad586c6b6fef8b23d1b0ff04
# nonstandard muggle, duplicated in yaml
# TODO remove this https://github.com/subugoe/shinycaas/issues/32
RUN ["bash", "-c", "curl -sL https://aka.ms/InstallAzureCLIDeb | bash"]
CMD shinycaas::az_webapp_shiny_opts(); shinycaas::runOldFaithful()
