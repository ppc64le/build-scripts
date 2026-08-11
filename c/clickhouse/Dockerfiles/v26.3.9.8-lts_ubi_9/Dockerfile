ARG PACKAGE_VERSION="v26.3.9.8-lts"
ARG PACKAGE_NAME="ClickHouse"

FROM registry.access.redhat.com/ubi9/ubi:9.7 AS build

ARG PACKAGE_VERSION
ARG PACKAGE_NAME
ENV PACKAGE_ORG="ClickHouse"
ENV PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/clickhouse/clickhouse-${PACKAGE_VERSION}.patch
ENV PATCH_FILE_LIBUNWIND=https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/clickhouse/clickhouse-${PACKAGE_VERSION}-llvm-project.patch
ENV CC=clang
ENV CXX=clang++

#Install required repos
RUN yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os && \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os && \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os && \
    rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

#Install dependencies
RUN dnf install -y git gcc gcc-c++ cmake ccache python3 ninja-build yasm gawk wget nasm xz gnupg kernel-headers expect python3-jinja2 hostname perl-FindBin perl-IPC-Cmd perl-File-Compare perl-File-Copy perl-Time-Piece perl-Pod-Html clang-22.1.3-1.el9.ppc64le llvm-22.1.3-1.el9.ppc64le lld-22.1.3-1.el9.ppc64le

#Install rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    source "$HOME/.cargo/env" && \
    rustup toolchain install nightly-2025-07-07 && \
    rustup default nightly-2025-07-07 && \
    rustup component add rust-src

#Clone
WORKDIR /usr/src
RUN wget ${PATCH_FILE} && \
    wget ${PATCH_FILE_LIBUNWIND} && \
    git clone $PACKAGE_URL -b $PACKAGE_VERSION && \
    cd $PACKAGE_NAME && \
    git submodule update --init --recursive --jobs $(nproc) && \
    git apply ../clickhouse-${PACKAGE_VERSION}.patch && \
    pushd contrib/llvm-project && git apply ../../../clickhouse-${PACKAGE_VERSION}-llvm-project.patch && popd && \
    cp /usr/include/linux/vm_sockets.h contrib/sysroot/linux-powerpc64le/powerpc64le-linux-gnu/libc/usr/include/linux/

#Build openssl
WORKDIR /usr/src/$PACKAGE_NAME/contrib/openssl
RUN ./config no-module && \
make -j$(nproc) && \
make install

#Build
WORKDIR /usr/src/$PACKAGE_NAME
RUN mkdir build && \
    cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D ENABLE_OPENSSL_DYNAMIC=ON .. && \
    ninja -j$(nproc)

WORKDIR /usr/src/$PACKAGE_NAME/build
RUN rm -rf programs/libcrypto.so.3 programs/libssl.so.3 && \
    cp /usr/local/lib/libcrypto.so.3 /usr/local/lib/libssl.so.3 programs/

FROM registry.access.redhat.com/ubi9/ubi:9.7

ARG PACKAGE_VERSION
ARG PACKAGE_NAME

RUN yum update -y && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    yum install wget tzdata ca-certificates langpacks-en busybox -y && \
    busybox --install -s

RUN wget -P /etc/clickhouse-server/config.d/ https://raw.githubusercontent.com/ClickHouse/ClickHouse/refs/tags/$PACKAGE_VERSION/docker/server/docker_related_config.xml && \
    wget -P / https://raw.githubusercontent.com/ClickHouse/ClickHouse/refs/tags/$PACKAGE_VERSION/docker/server/entrypoint.sh
RUN chmod +x /entrypoint.sh

ARG DEFAULT_UID="101"
ARG DEFAULT_GID="101"
RUN groupadd -r clickhouse --gid=${DEFAULT_GID} && \
    useradd -r -g clickhouse --uid=${DEFAULT_UID} --home-dir=/var/lib/clickhouse --shell=/bin/bash clickhouse

COPY --from=build /usr/src/$PACKAGE_NAME/build/programs/clickhouse /tmp/
COPY --from=build /usr/src/$PACKAGE_NAME/build/programs/libcrypto.so.3 /tmp/
COPY --from=build /usr/src/$PACKAGE_NAME/build/programs/libssl.so.3 /tmp/
RUN mv /tmp/libcrypto.so.3 /usr/lib64/libcrypto.so.3 && \
    mv /tmp/libssl.so.3 /usr/lib64/libssl.so.3 && \
    /tmp/clickhouse install --user "clickhouse" --group "clickhouse" && \
    rm -rf /tmp/*

RUN clickhouse-local -q 'SELECT * FROM system.build_options' \
    && mkdir -p /var/lib/clickhouse /var/log/clickhouse-server /etc/clickhouse-server /etc/clickhouse-client \
    && chmod ugo+Xrw -R /var/lib/clickhouse /var/log/clickhouse-server /etc/clickhouse-server /etc/clickhouse-client

ENV LANG=en_US.UTF-8
ENV TZ=UTC

RUN mkdir /docker-entrypoint-initdb.d

EXPOSE 9000 8123 9009
VOLUME /var/lib/clickhouse

ENV CLICKHOUSE_CONFIG=/etc/clickhouse-server/config.xml

ENTRYPOINT ["/entrypoint.sh"]

