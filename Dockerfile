ARG MUGGLE_TAG=a94fcb785886af96d440b4bcd7f47c01162d7f5e
FROM subugoe/muggle-buildtime-onbuild:${MUGGLE_TAG} as buildtime
FROM subugoe/muggle-runtime-onbuild:${MUGGLE_TAG} as runtime
CMD shinycaas::az_webapp_shiny_opts(); shinycaas::runOldFaithful()
