FROM registry.access.redhat.com/ubi9/ubi:9.7 AS builder

ARG PACKAGE_VERSION=r8.3.1
ARG MONGO_VERSION=8.3.1

ENV PACKAGE_VERSION=${PACKAGE_VERSION}
ENV MONGO_VERSION=${MONGO_VERSION}
ENV MONGO_MAJOR=8.3
ENV PYTHON_VERSION=3.10.20
ENV GO_VERSION=1.25.9

# -------------------------
# Base build dependencies
# -------------------------
RUN set -eux; \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os; \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os; \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os; \
    rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official; \
    yum install -y \
        git wget tar gzip make findutils \
        gcc gcc-c++ \
        openssl-devel zlib-devel xz-devel \
        libcurl-devel cyrus-sasl-devel krb5-devel \
        libffi-devel readline-devel sqlite-devel \
        ncurses-devel tk-devel bzip2-devel \
        gdbm-devel libdb-devel libnsl2-devel \
        pkgconf-pkg-config pkg-config \
        python3-devel ca-certificates \
        gcc-toolset-14 \
    && yum clean all

# Go environment
ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH=${PATH}:${GOROOT}/bin:${GOPATH}/bin:/usr/local/bin

# Install Go for ppc64le
RUN wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz \
    && rm -f go${GO_VERSION}.linux-ppc64le.tar.gz \
    && go version

# -------------------------
# Mongo-tools build
# -------------------------
RUN set -eux; \
    cd /root; \
    git clone https://github.com/mongodb/mongo-tools.git; \
    cd mongo-tools; \
    ./make build; \
    mkdir -p /out; \
    cp -a bin /out/

# enable toolchain
RUN source /opt/rh/gcc-toolset-14/enable && gcc --version

# -------------------------
# Python build (required for Mongo buildscripts)
# -------------------------
RUN set -eux; \
    cd /tmp; \
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz; \
    tar xzf Python-${PYTHON_VERSION}.tgz; \
    cd Python-${PYTHON_VERSION}; \
    ./configure --prefix=/usr/local --enable-optimizations; \
    make -j$(nproc); \
    make altinstall; \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python3; \
    ln -sf /usr/local/bin/python3.10 /usr/bin/python; \
    ln -sf /usr/local/bin/pip3.10 /usr/bin/pip3; \
    python3 -V; \
    cd / && rm -rf /tmp/Python-${PYTHON_VERSION}*

# -------------------------
# MongoDB source build
# -------------------------
RUN set -eux; \
    source /opt/rh/gcc-toolset-14/enable; \
    mkdir -p /src; \
    cd /src; \
    git clone https://github.com/mongodb/mongo; \
    cd mongo; \
    git checkout ${PACKAGE_VERSION}; \
    git submodule update --init --recursive; \
    \
    python buildscripts/install_bazel.py; \
    export PATH=/root/.local/bin:$PATH; \
    GIT_HASH=$(git rev-parse HEAD); \
    echo "Building with git hash: $GIT_HASH"; \
    \
    bazel build \
        //:install-mongod \
        //:install-mongos \
        --config=opt \
        --config=local \
        --//bazel/config:build_enterprise=false \
        --//bazel/config:separate_debug=True \
        --action_env=MONGO_VERSION=${MONGO_VERSION} \
        --define=MONGO_VERSION=${MONGO_VERSION} \
        --define=GIT_COMMIT_HASH=${GIT_HASH} \
        --//bazel/config:release=True \
        --disable_warnings_as_errors=True \
        --jobs=$(nproc); \
    \
    mkdir -p /out; \
    cp bazel-bin/install-mongod/bin/mongod /out/; \
    cp bazel-bin/install-mongos/bin/mongos /out/

# -------------------------
# cleanup build layer
# -------------------------
RUN rm -rf /src /root/.cache


FROM registry.access.redhat.com/ubi9/ubi:9.7

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux; \
        groupadd --gid 1000 --system mongodb; \
        useradd --uid 1000 --system --gid mongodb --home-dir /data/db mongodb; \
        mkdir -p /data/db /data/configdb; \
        chown -R mongodb:mongodb /data/db /data/configdb

RUN set -eux; \
        yum install -y \
                ca-certificates \
                jq; \
                # numactl; \
        if ! command -v ps > /dev/null; then \
                yum install -y procps-ng; \
        fi; \
        rm -rf /var/cache/yum

# grab gosu for easy step-down from root (https://github.com/tianon/gosu/releases)
ENV GOSU_VERSION=1.19
# grab "js-yaml" for parsing mongod's YAML config files (https://github.com/nodeca/js-yaml/releases)
ENV JSYAML_VERSION=3.13.1
ENV JSYAML_CHECKSUM=662e32319bdd378e91f67578e56a34954b0a2e33aca11d70ab9f4826af24b941

RUN set -eux; \
        yum install -y wget gnupg2; \
        rm -rf /var/cache/yum; \
        rpmArch="ppc64el"; \
        wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$rpmArch"; \
        wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$rpmArch.asc"; \
        export GNUPGHOME="$(mktemp -d)"; \
        gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
        gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
        gpgconf --kill all; \
        rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc

# download/install js-yaml
RUN mkdir -p /opt/js-yaml && \
    wget -O /opt/js-yaml/js-yaml.tgz \
    https://registry.npmjs.org/js-yaml/-/js-yaml-${JSYAML_VERSION}.tgz && \
    echo "$JSYAML_CHECKSUM */opt/js-yaml/js-yaml.tgz" | sha256sum -c - && \
    tar -xz --strip-components=1 \
        -f /opt/js-yaml/js-yaml.tgz \
        -C /opt/js-yaml package/dist/js-yaml.js package/package.json && \
    ln -s /opt/js-yaml/dist/js-yaml.js /js-yaml.js

# download/install MongoDB PGP keys
RUN set -eux; \
        export GNUPGHOME="$(mktemp -d)"; \
        wget -O KEYS 'https://pgp.mongodb.com/server-8.0.asc'; \
        gpg --batch --import KEYS; \
        mkdir -p /etc/apt/keyrings; \
        gpg --batch --export --armor '4B0752C1BCA238C0B4EE14DC41DE058A4E7DCA05' > /etc/pki/rpm-gpg/mongodb.asc; \
        gpgconf --kill all; \
        rm -rf "$GNUPGHOME" KEYS; \
        yum autoremove -y; \
        yum clean all; \

# smoke test
        chmod +x /usr/local/bin/gosu; \
        gosu --version; \
        gosu nobody true

RUN mkdir /docker-entrypoint-initdb.d

ENV MONGO_MAJOR=8.3
ENV MONGO_VERSION=8.3.1
ENV MONGOSH_VERSION=2.8.3
# https://docs.mongodb.org/master/release-notes/8.3/
# 05/05/2026, https://github.com/mongodb/mongo/tree/89f54eb32e217d2f7bfcad50e5919f3033bb9611


RUN yum install -y wget tar && \
        mkdir -p /tmp/mongosh-${MONGOSH_VERSION} && \
        cd /tmp/mongosh-${MONGOSH_VERSION} && \
        echo "Installing mongosh shell..." && \
        wget https://downloads.mongodb.com/compass/mongosh-${MONGOSH_VERSION}-linux-ppc64le.tgz && \
        tar -zxvf mongosh-${MONGOSH_VERSION}-linux-ppc64le.tgz && \
        cp mongosh-${MONGOSH_VERSION}-linux-ppc64le/bin/mongosh /usr/bin/mongosh && \
        cp mongosh-${MONGOSH_VERSION}-linux-ppc64le/bin/mongosh_crypt_v1.so /usr/lib/ && \
        chmod +x /usr/bin/mongosh && \
        rm -f mongosh-${MONGOSH_VERSION}-linux-ppc64le.tgz && \
        rm -rf mongosh-${MONGOSH_VERSION}-linux-ppc64le && \
        rm -rf /tmp/mongosh-* && \
    yum remove -y wget tar && \
    yum clean all && \
    rm -rf /var/cache/yum

# -------------------------
# Copy MongoDB binaries
# -------------------------
COPY --from=builder /out/mongod /usr/bin/mongod
COPY --from=builder /out/mongos /usr/bin/mongos


# -------------------------
# Mongo-tools binaries
# -------------------------
COPY --from=builder /out/bin/ /usr/bin/

VOLUME /data/db /data/configdb

# ensure that if running as custom user that "mongosh" has a valid "HOME"
# https://github.com/docker-library/mongo/issues/524
ENV HOME /data/db

# ensure that glibc isn't using rseq so that google-tcmalloc can
# https://www.mongodb.com/docs/manual/administration/tcmalloc-performance/#disable-glibc-rseq
ENV GLIBC_TUNABLES glibc.pthread.rseq=0

COPY docker-entrypoint.sh /usr/local/bin/

# backwards compat
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh \
        && chmod +x /usr/local/bin/docker-entrypoint.sh \
        && chmod +x /entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 27017
CMD ["mongod"]

