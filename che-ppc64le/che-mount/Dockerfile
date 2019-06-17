# Copyright (c) 2012-2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Tyler Jewell - Initial implementation
#

FROM alpine:3.6

ENV UNISON_VERSION=2.51.2

RUN apk add --update build-base curl bash sshfs ocaml && \
    curl -L https://www.seas.upenn.edu/~bcpierce/unison/download/releases/unison-$UNISON_VERSION/unison-$UNISON_VERSION.tar.gz | tar xzv -C /tmp && \
    cd /tmp/src && \
    sed -i -e 's/GLIBC_SUPPORT_INOTIFY 0/GLIBC_SUPPORT_INOTIFY 1/' fsmonitor/linux/inotify_stubs.c && \
   make && \
   cp /tmp/src/unison /usr/local/bin && \
   cp /tmp/src/unison-fsmonitor /usr/local/bin && \
    apk del ocaml curl build-base bash && \
    rm -rf /tmp /var/cache/apk/* && \
    mkdir /mntssh && chmod -R 777 /mntssh && \
    mkdir /mnthost && chmod -R 777 /mnthost

ENV DOCKER_BUCKET get.docker.com
ENV DOCKER_VERSION 1.6.0

RUN set -x \
    && apk add --no-cache \
    ca-certificates \
    curl \
    openssl \
    && curl -sL "https://${DOCKER_BUCKET}/builds/Linux/ppc64le/docker-$DOCKER_VERSION" \
    > /usr/bin/docker; chmod +x /usr/bin/docker \
    && apk del curl ca-certificates openssl

COPY /entrypoint.sh /bin/entrypoint.sh

ENTRYPOINT ["/bin/entrypoint.sh"]
