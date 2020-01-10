# This Dockerfile has been adapted from the Dockerfile
# maintained by the ManageIQ community at
# https://github.com/ManageIQ/manageiq-pods
# to work on Power on UBI base
ARG FROM_REPO=manageiq
ARG FROM_TAG=ubi7-latest

FROM ${FROM_REPO}/manageiq-base-worker:${FROM_TAG}
MAINTAINER ManageIQ https://manageiq.org

LABEL name="manageiq-webserver-worker" \
      summary="ManageIQ web server worker image"

EXPOSE 3000
