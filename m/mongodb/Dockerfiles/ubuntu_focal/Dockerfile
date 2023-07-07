# This file has been adapted from the original work at "https://github.com/CrimsonGlory/mongo_ppc64le/blob/master/Dockerfile" to build on Power
#
FROM ubuntu:focal
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN set -eux; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
                ca-certificates \
                jq \
                numactl \
        ; \
        if ! command -v ps > /dev/null; then \
                apt-get install -y --no-install-recommends procps; \
        fi; \
        rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root (https://github.com/tianon/gosu/releases)
ENV GOSU_VERSION 1.12
# grab "js-yaml" for parsing mongod's YAML config files (https://github.com/nodeca/js-yaml/releases)
ENV JSYAML_VERSION 3.13.1

RUN set -ex; \
        \
        savedAptMark="$(apt-mark showmanual)"; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
                wget \
        ; \
        if ! command -v gpg > /dev/null; then \
                apt-get install -y --no-install-recommends gnupg dirmngr; \
                savedAptMark="$savedAptMark gnupg dirmngr"; \
        elif gpg --version | grep -q '^gpg (GnuPG) 1\.'; then \
# "This package provides support for HKPS keyservers." (GnuPG 1.x only)
                apt-get install -y --no-install-recommends gnupg-curl; \
        fi; \
        rm -rf /var/lib/apt/lists/*; \
        \
        dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
        wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
        wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
        export GNUPGHOME="$(mktemp -d)"; \
        gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
        gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
        command -v gpgconf && gpgconf --kill all || :; \
        rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
        \
        wget -O /js-yaml.js "https://github.com/nodeca/js-yaml/raw/${JSYAML_VERSION}/dist/js-yaml.js"; \
# TODO some sort of download verification here
        \
        apt-mark auto '.*' > /dev/null; \
        apt-mark manual $savedAptMark > /dev/null; \
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
        \
# smoke test
        chmod +x /usr/local/bin/gosu; \
        gosu --version; \
        gosu nobody true

RUN mkdir /docker-entrypoint-initdb.d

RUN set -ex; \
        export GNUPGHOME="$(mktemp -d)"; \
        set -- '20691EEC35216C63CAF66CE1656408E390CFB1F5'; \
        for key; do \
                gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key"; \
        done; \
        gpg --batch --export "$@" > /etc/apt/trusted.gpg.d/mongodb.gpg; \
        command -v gpgconf && gpgconf --kill all || :; \
        rm -r "$GNUPGHOME"; \
        apt-key list

ENV MONGO_MAJOR 4.4
ARG MONGO_VERSION=4.4.22

# We install the necesary tools to compile mongo on ppc64le
RUN apt-get update \
        && apt-get upgrade -y \
        && apt-get install -y --no-install-recommends \
                unzip \
                git \
                build-essential \
                wget \
                ca-certificates \
                libcurl4-openssl-dev \
                libssl-dev python3-dev python3-pip \
                scons \
#        && apt-get install -y python3-pip \
        && rm -rf /var/lib/apt/lists/* \
        && mkdir -p /tmp/mongodb-src-r${MONGO_VERSION} \
        && cd /tmp/mongodb-src-r${MONGO_VERSION} \
        && git clone https://github.com/mongodb/mongo.git && cd mongo \
        && git checkout r${MONGO_VERSION} \
        && python3 -m pip install -r etc/pip/compile-requirements.txt \
        && python3 buildscripts/scons.py install-mongod install-mongo --separate-debug=on --disable-warnings-as-errors DESTDIR=/usr/ --ssl=on --no-cache --release \
        && apt-get purge -y --auto-remove \
                ca-certificates \
                wget \
                unzip \
                git \
                build-essential \
                python3 \
                python3-pip python3-setuptools \
                libssl-dev \
                scons \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /tmp/mongodb-src-r${MONGO_VERSION} \
        && rm -f /tmp/mongodb.zip 
# ToDo: uninstall scons


RUN mkdir -p /data/db /data/configdb \
        && chown -R mongodb:mongodb /data/db /data/configdb
VOLUME /data/db /data/configdb

COPY docker-entrypoint.sh /usr/local/bin/

# backwards compat
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh \
        && chmod +x /usr/local/bin/docker-entrypoint.sh \
        && chmod +x /entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 27017

USER mongodb

CMD ["mongod"]
