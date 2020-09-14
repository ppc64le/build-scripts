# This Dockerfile has been adapted from the Dockerfile
# maintained by the ManageIQ community at
# https://github.com/ManageIQ/manageiq-pods
# to work on Power on UBI base
ARG FROM_REPO=manageiq
ARG FROM_TAG=ubi7-latest

FROM ${FROM_REPO}/manageiq-base:${FROM_TAG}
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

LABEL name="manageiq-base-worker" \
      summary="ManageIQ Worker Image"

COPY container-assets/entrypoint /usr/local/bin
COPY container-assets/manageiq_liveness_check /usr/local/bin

CMD ["entrypoint"]
