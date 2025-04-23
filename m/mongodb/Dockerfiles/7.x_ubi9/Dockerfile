FROM registry.access.redhat.com/ubi9/ubi:latest

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux; \
        groupadd --gid 1000 --system mongodb; \
        useradd --uid 1000 --system --gid mongodb --home-dir /data/db mongodb; \
        mkdir -p /data/db /data/configdb; \
        chown -R mongodb:mongodb /data/db /data/configdb
RUN set -eux; \
        yum update -y; \
        yum install -y \
                ca-certificates \
                jq; \
                # numactl; \
        if ! command -v ps > /dev/null; then \
                yum install -y procps-ng; \
        fi; \
        rm -rf /var/cache/yum

# grab gosu for easy step-down from root (https://github.com/tianon/gosu/releases)
ENV GOSU_VERSION 1.17
# grab "js-yaml" for parsing mongod's YAML config files (https://github.com/nodeca/js-yaml/releases)
ENV JSYAML_VERSION 3.13.1
ENV JSYAML_CHECKSUM 662e32319bdd378e91f67578e56a34954b0a2e33aca11d70ab9f4826af24b941

RUN set -eux; \
        \
        # savedAptMark="$(apt-mark showmanual)"; \
        yum update -y; \
        yum install -y \
                wget \
                gnupg2 \
        ; \
        rm -rf /var/cache/yum ; \
        rpmArch="ppc64el"; \
        # rpmArch="$(uname -m)"; \
        wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$rpmArch"; \
        wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$rpmArch.asc"; \
        export GNUPGHOME="$(mktemp -d)"; \
        gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
        gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
        gpgconf --kill all; \
        rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
        \
# download/install js-yaml
        mkdir -p /opt/js-yaml/; \
        wget -O /opt/js-yaml/js-yaml.tgz https://registry.npmjs.org/js-yaml/-/js-yaml-${JSYAML_VERSION}.tgz; \
        echo "$JSYAML_CHECKSUM */opt/js-yaml/js-yaml.tgz" | sha256sum -c -; \
        tar -xz --strip-components=1 -f /opt/js-yaml/js-yaml.tgz -C /opt/js-yaml package/dist/js-yaml.js package/package.json; \
        rm /opt/js-yaml/js-yaml.tgz; \
        ln -s /opt/js-yaml/dist/js-yaml.js /js-yaml.js; \

# smoke test
        chmod +x /usr/local/bin/gosu; \
        gosu --version; \
        gosu nobody true

# download/install MongoDB PGP keys
RUN set -eux; \
        export GNUPGHOME="$(mktemp -d)"; \
        wget -O KEYS 'https://pgp.mongodb.com/server-7.0.asc'; \
        gpg --batch --import KEYS; \
        mkdir -p /etc/pki/rpm-gpg; \
        gpg --batch --export --armor 'E58830201F7DD82CD808AA84160D26BB1785BA38' > /etc/pki/rpm-gpg/mongodb.asc; \
        gpgconf --kill all; \
        rm -rf "$GNUPGHOME" KEYS; \
        yum autoremove -y; \
        yum clean all

RUN mkdir /docker-entrypoint-initdb.d

ARG MONGO_MAJOR=7.0
ARG MONGO_VERSION=7.3.4
# We install the necesary tools to compile mongo on ppc64le
RUN yum update -y \
        && yum upgrade -y \
        && yum install -y \
                rust \
                cargo \
                unzip \
                git \
                make \
                gcc \
                gcc-c++ \
                wget \
                ca-certificates \
                libcurl-devel \
                python3-devel \
                python3-pip \
                xz-devel \
                openssl-devel \
        && rm -rf /var/cache/yum \
        && mkdir -p /tmp/mongodb-src-r${MONGO_VERSION} \
        && cd /tmp/mongodb-src-r${MONGO_VERSION} \
        && git clone https://github.com/mongodb/mongo.git && cd mongo \
        && git checkout r${MONGO_VERSION} \
        && pip install scons maturin mongo_tooling_metrics psutil memory_profiler puremagic networkx cxxfilt pyyaml cheetah3 \
        && pip install cryptography \
        && python3 -m pip install 'poetry==1.5.1' \
        && python3 -m poetry install --no-root --sync \
        && python3 buildscripts/scons.py -j6 install-mongod install-mongos --separate-debug=on --disable-warnings-as-errors DESTDIR=/usr/ --ssl=on --no-cache --release --linker=gold \
        && poetry env remove python3 \
        && pip uninstall -y scons maturin mongo_tooling_metrics psutil memory_profiler puremagic networkx cxxfilt pyyaml cheetah3 cryptography poetry \
        && yum remove -y --skip-broken --nobest \
                git \
                rust \
                python3-pip python3-setuptools \
                cargo \
                make \
                libcurl-devel \
                openssl-devel \
                wget \
                xz-devel \
                gcc \
                gcc-c++ \
                wget \
                unzip \
        && yum clean all \
        && rm -rf /var/cache/yum \
        && rm -rf /tmp/mongodb-src-r${MONGO_VERSION} \
        && rm -f /tmp/mongodb.zip

# ToDo: uninstall scons
RUN yum update && \
    yum install -y wget && \
    mkdir -p /tmp/mongosh-2.3.4 && \
    cd /tmp/mongosh-2.3.4 && \
    wget https://downloads.mongodb.com/compass/mongosh-2.3.4-linux-ppc64le.tgz && \
    tar -zxvf mongosh-2.3.4-linux-ppc64le.tgz && \
    cp /tmp/mongosh-2.3.4/mongosh-2.3.4-linux-ppc64le/bin/mongosh /usr/local/bin/ && \
    cp /tmp/mongosh-2.3.4/mongosh-2.3.4-linux-ppc64le/bin/mongosh_crypt_v1.so /usr/local/lib/ && \
    ln -s $(pwd)/bin/* /usr/local/bin/ && \
    rm -f /tmp/mongosh-2.3.4/mongosh-2.3.4-linux-ppc64le.tgz && \
    rm -rf /tmp/mongosh-2.3.4/mongosh-2.3.4-linux-ppc64le/
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
