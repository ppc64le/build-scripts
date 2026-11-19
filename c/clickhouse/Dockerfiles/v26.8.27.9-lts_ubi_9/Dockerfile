ARG PACKAGE_VERSION="v26.8.27.9-lts"
ARG PACKAGE_NAME="ClickHouse"

FROM registry.access.redhat.com/ubi9/ubi:9.8 AS build

ARG PACKAGE_VERSION
ARG PACKAGE_NAME
ARG BUILD_JOBS=4
ENV PACKAGE_ORG="ClickHouse"
ENV PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}"
ENV CC=clang
ENV CXX=clang++

# Install required repos
RUN yum install -y yum-utils && \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/ && \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/ && \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/ && \
    rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256 && \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install dependencies
RUN dnf install -y git gcc gcc-c++ cmake ccache python3 ninja-build yasm gawk wget nasm xz gnupg \
    kernel-headers expect python3-jinja2 hostname \
    perl-FindBin perl-IPC-Cmd perl-File-Compare perl-File-Copy perl-Time-Piece perl-Pod-Html \
    clang-22.1.8-1.el9.ppc64le llvm-22.1.8-1.el9.ppc64le lld-22.1.8-1.el9.ppc64le libunwind libunwind-devel

# Install Rust
ENV PATH="/root/.cargo/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    rustup toolchain install nightly-2026-03-22 && \
    rustup default nightly-2026-03-22 && \
    rustup component add rust-src && \
    rustup target add powerpc64le-unknown-linux-gnu

# Clone and patch (the patch files sit next to this Dockerfile, which is the build context)
WORKDIR /usr/src
COPY clickhouse-${PACKAGE_VERSION}.patch clickhouse-${PACKAGE_VERSION}-llvm-project.patch /usr/src/
RUN git clone $PACKAGE_URL -b $PACKAGE_VERSION $PACKAGE_NAME && \
    cd $PACKAGE_NAME && \
    git submodule update --init --recursive --jobs $(nproc) && \
    git apply ../clickhouse-${PACKAGE_VERSION}.patch && \
    pushd contrib/llvm-project && git apply ../../../clickhouse-${PACKAGE_VERSION}-llvm-project.patch && popd && \
    cp /usr/include/linux/vm_sockets.h contrib/sysroot/linux-powerpc64le/powerpc64le-linux-gnu/libc/usr/include/linux/

# Build OpenSSL
WORKDIR /usr/src/$PACKAGE_NAME/contrib/openssl
RUN ./config no-module && \
    make -j$(nproc) && \
    make install

# Build ClickHouse (POWER10 option only when a POWER10 CPU is detected; jobs capped to limit peak RAM)
WORKDIR /usr/src/$PACKAGE_NAME
RUN mkdir build && \
    cd build && \
    POWER10_OPT="" && \
    if grep -iq POWER10 /proc/cpuinfo || lscpu | grep -iq POWER10; then POWER10_OPT="-D POWER10=1"; fi && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D ENABLE_TESTS=OFF \
          -D ENABLE_OPENSSL_DYNAMIC=ON \
          -D ENABLE_CLICKHOUSE_KEEPER=ON \
          -D ENABLE_CLICKHOUSE_KEEPER_CONVERTER=ON \
          -D ENABLE_CLICKHOUSE_KEEPER_CLIENT=ON \
          ${POWER10_OPT} .. && \
    ninja -j${BUILD_JOBS}

WORKDIR /usr/src/$PACKAGE_NAME/build
RUN rm -rf programs/libcrypto.so.3 programs/libssl.so.3 && \
    cp /usr/local/lib/libcrypto.so.3 /usr/local/lib/libssl.so.3 programs/

# --- Runtime image ---
FROM registry.access.redhat.com/ubi9/ubi:9.8

ARG PACKAGE_VERSION
ARG PACKAGE_NAME

RUN yum update -y && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    yum install -y wget tzdata ca-certificates langpacks-en busybox && \
    busybox --install -s && \
    yum clean all && rm -rf /var/cache/yum /var/cache/dnf

RUN wget -P /etc/clickhouse-server/config.d/ \
    https://raw.githubusercontent.com/ClickHouse/ClickHouse/refs/tags/$PACKAGE_VERSION/docker/server/docker_related_config.xml && \
    wget -P / \
    https://raw.githubusercontent.com/ClickHouse/ClickHouse/refs/tags/$PACKAGE_VERSION/docker/server/entrypoint.sh
RUN chmod +x /entrypoint.sh

ARG DEFAULT_UID="101"
ARG DEFAULT_GID="101"
RUN groupadd -r clickhouse --gid=${DEFAULT_GID} && \
    useradd -r -g clickhouse --uid=${DEFAULT_UID} --home-dir=/var/lib/clickhouse --shell=/bin/bash clickhouse

# Install straight from the build stage with a bind mount, so the 900 MB binary is stored once in the image
# (COPY into the image and then "clickhouse install" would keep two copies, one per layer). Needs BuildKit.
# The OpenSSL libs replace the /usr/lib64/*.so.3 symlinks (rm first), so the versioned openssl-libs files stay intact.
RUN --mount=type=bind,from=build,source=/usr/src/$PACKAGE_NAME/build/programs,target=/mnt/ch \
    rm -f /usr/lib64/libcrypto.so.3 /usr/lib64/libssl.so.3 && \
    cp /mnt/ch/libcrypto.so.3 /mnt/ch/libssl.so.3 /usr/lib64/ && \
    /mnt/ch/clickhouse install --user "clickhouse" --group "clickhouse"

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
