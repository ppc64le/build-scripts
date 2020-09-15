# Adapted from the original work for Intel by Lachlan Evenson here
# https://github.com/lachie83/k8s-helm/blob/v2.9.1/Dockerfile

FROM alpine

MAINTAINER "Sandip Giri <sgiri@us.ibm.com>"

ARG VCS_REF
ARG BUILD_DATE

# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/lachie83/k8s-helm" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile"

ENV HELM_LATEST_VERSION="v2.9.1"

RUN apk add --update ca-certificates \
&& apk add --update -t deps wget \
&& wget https://storage.googleapis.com/kubernetes-helm/helm-${HELM_LATEST_VERSION}-linux-ppc64le.tar.gz \
&& tar -xvf helm-${HELM_LATEST_VERSION}-linux-ppc64le.tar.gz \
&& mv linux-ppc64le/helm /usr/local/bin \
&& apk del --purge deps \
&& rm /var/cache/apk/* \
&& rm -f /helm-${HELM_LATEST_VERSION}-linux-ppc64le.tar.gz

ENTRYPOINT ["helm"]
CMD ["help"]
