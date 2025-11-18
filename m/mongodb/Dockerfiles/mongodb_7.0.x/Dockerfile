# This file has been adapted from the original work at "https://github.com/CrimsonGlory/mongo_ppc64le/blob/master/Dockerfile" to build on Power
#
FROM ubuntu:jammy
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux; \
        groupadd --gid 999 --system mongodb; \
        useradd --uid 999 --system --gid mongodb --home-dir /data/db mongodb; \
        mkdir -p /data/db /data/configdb; \
        chown -R mongodb:mongodb /data/db /data/configdb

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
ENV GOSU_VERSION 1.19
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
# download/install js-yaml
        mkdir -p /opt/js-yaml/; \
        wget -O /opt/js-yaml/js-yaml.js "https://github.com/nodeca/js-yaml/raw/${JSYAML_VERSION}/dist/js-yaml.js"; \
        wget -O /opt/js-yaml/package.json "https://github.com/nodeca/js-yaml/raw/${JSYAML_VERSION}/package.json"; \
        ln -s /opt/js-yaml/js-yaml.js /js-yaml.js; \
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

ARG MONGO_MAJOR=7.0
ARG MONGO_VERSION=7.0.25
ARG MONGOSH_VERSION=2.5.9

# We install the necesary tools to compile mongo on ppc64le
RUN echo "Updating and installing build dependencies..." \
        && apt-get update \
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
                liblzma-dev \
                cargo \
        && rm -rf /var/lib/apt/lists/* \
        && mkdir -p /tmp/mongodb-src-r${MONGO_VERSION} \
        && cd /tmp/mongodb-src-r${MONGO_VERSION} \
        && git clone https://github.com/mongodb/mongo.git && cd mongo \
        && git checkout r${MONGO_VERSION} \
        && python3 -m pip install mongo-tooling-metrics \
        && python3 -m pip install --upgrade pip setuptools wheel \
        && python3 -m pip install cryptography==36.0.2 \
        && python3 -m pip install -r etc/pip/compile-requirements.txt \
        && ln -s /usr/bin/python3 /usr/bin/python \
        && python3 buildscripts/scons.py install-mongod install-mongos -j$(nproc) --separate-debug=on --disable-warnings-as-errors DESTDIR=/usr/ --ssl=on --no-cache --release --dbg=off --opt=on --linker=gold \
        && python3 -m pip uninstall -y cryptography setuptools wheel \
        && rm -rf /root/.cache/pip \
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
                liblzma-dev \
                cargo \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /tmp/mongodb-src-r${MONGO_VERSION} \
        && rm -f /tmp/mongodb.zip
   
RUN apt-get update && \
        apt-get install -y wget && \
        mkdir -p /tmp/mongosh-$MONGOSH_VERSION && \
        cd /tmp/mongosh-$MONGOSH_VERSION && \
        echo "Installing mongosh shell..." && \
        wget https://downloads.mongodb.com/compass/mongosh-$MONGOSH_VERSION-linux-ppc64le.tgz && \
        tar -zxvf mongosh-$MONGOSH_VERSION-linux-ppc64le.tgz && \
        cp /tmp/mongosh-$MONGOSH_VERSION/mongosh-$MONGOSH_VERSION-linux-ppc64le/bin/mongosh /usr/local/bin/ && \
        cp /tmp/mongosh-$MONGOSH_VERSION/mongosh-$MONGOSH_VERSION-linux-ppc64le/bin/mongosh_crypt_v1.so /usr/local/lib/ && \
        ln -s $(pwd)/bin/* /usr/local/bin/ && \
        rm -f /tmp/mongosh-$MONGOSH_VERSION/mongosh-$MONGOSH_VERSION-linux-ppc64le.tgz && \
        rm -rf /tmp/mongosh-$MONGOSH_VERSION/mongosh-$MONGOSH_VERSION-linux-ppc64le/

VOLUME /data/db /data/configdb

ENV HOME /data/db

COPY docker-entrypoint.sh /usr/local/bin/

# backwards compat
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 27017

USER mongodb

CMD ["mongod"]

