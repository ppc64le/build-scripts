#Dockerfile for Ghost
FROM ppc64le/node:6.10

# Owner of a docker file
# This docker file is derived from original work for x86 @https://github.com/docker-library/ghost
# email : Sandip Giri <sgiri@us.ibm.com>
MAINTAINER Sandip Giri

ENV GHOST_SOURCE /usr/src/ghost
WORKDIR $GHOST_SOURCE

ENV GHOST_VERSION 0.11.5

RUN apt-get update && \
        apt-get install -y unzip build-essential && \
        wget -O ghost.zip "https://github.com/TryGhost/Ghost/releases/download/${GHOST_VERSION}/Ghost-${GHOST_VERSION}.zip" \
        && unzip ghost.zip \
        && npm install --production \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false unzip  build-essential \
        && rm ghost.zip \
        && npm cache clean \
        && rm -rf /tmp/npm*

COPY config.js $GHOST_SOURCE/config.js

RUN useradd -ms /bin/bash ghost \
        && chown -R ghost:ghost $GHOST_SOURCE \
        && su - ghost \
        && cd $GHOST_SOURCE


EXPOSE 2368
CMD ["npm", "start", "--production"]
