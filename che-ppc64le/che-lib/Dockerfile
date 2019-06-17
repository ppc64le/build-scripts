# Copyright (c) 2017 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0

FROM ppc64le/node:11.12-alpine 

ENV DOCKER_BUCKET=get.docker.com \
    DOCKER_VERSION=1.6.0 \
    ARCH="`arch`"

RUN set -x \
        && apk add --no-cache \
        ca-certificates \
        curl \
        openssl \
        git \
        && curl -sL "https://${DOCKER_BUCKET}/builds/Linux/$ARCH/docker-$DOCKER_VERSION" \
        > /usr/bin/docker; chmod +x /usr/bin/docker \
        && apk del curl ca-certificates openssl

RUN cd $HOME && git clone https://github.com/Microsoft/TypeScript.git \
    && cd TypeScript \
    && npm install -g gulp && npm install \
    && gulp local

COPY runtime-dependencies/package.json /runtime/
COPY . /lib-typescript/

RUN cd /lib-typescript/ && npm install \
    && cd /runtime && npm install  && /lib-typescript/node_modules/.bin/tsc --project /lib-typescript/; exit 0
RUN mv /lib-typescript/lib /che-lib && cd /lib-typescript/src && find . -name "*.properties" -exec install -D {} /che-lib/{} \;\
    && rm -rf /lib-typescript && mv /runtime/node_modules /che-lib && rm -rf /runtime

