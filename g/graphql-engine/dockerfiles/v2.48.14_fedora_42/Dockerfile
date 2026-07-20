# ========================
# BUILD STAGE
# ========================

FROM fedora:42 AS build

ARG WDIR=/tmp
WORKDIR $WDIR

ARG PACKAGE_NAME=graphql-engine
ARG PACKAGE_VERSION=v2.48.14
ARG PACKAGE_ORG=hasura
ARG CABAL_VERSION=3.12.1.0

ENV PACKAGE_PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/g/${PACKAGE_NAME}/${PACKAGE_NAME}-${PACKAGE_VERSION}.patch 

# Install dependencies
RUN dnf install -y \
    git gcc-c++ g++ curl zlib-devel \
    cabal-install libpq-devel unixODBC-devel ghc9.10 \
    && dnf clean all	

# Setup cabal
RUN cabal user-config init && \
    sed -i 's|url: http://hackage.haskell.org/|url: https://hackage.haskell.org/|' $HOME/.config/cabal/config && \
    cabal update && \
    cabal install cabal-install-$CABAL_VERSION --overwrite-policy=always && \
    PATH="$HOME/.local/bin/:$PATH" && \
    cabal -V && \
    cabal update && \
    dnf -y remove ghc cabal-install	

#Copy patch
RUN wget $PACKAGE_PATCH && \
    cp ${PACKAGE_NAME}-${PACKAGE_VERSION}.patch $WDIR/
	
#COPY ${PACKAGE_NAME}-${PACKAGE_VERSION}.patch $WDIR/

# Build binary from source
RUN git clone https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git && \
    cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION} && \
    git apply $WDIR/${PACKAGE_NAME}-${PACKAGE_VERSION}.patch && \
    echo $PACKAGE_VERSION > "$(git rev-parse --show-toplevel)/server/CURRENT_VERSION" && \
    PATH="$HOME/.local/bin/:$PATH" && \
    rm -f cabal.project.freeze && \
    cabal build exe:graphql-engine && \
  # Copy final binary to /tmp
    cp "$(find dist-newstyle -type f -path '*/build/*/graphql-engine' | head -n 1)" /tmp/graphql-engine

FROM fedora:42 AS pg_dump_source

RUN dnf install -y postgresql17 && dnf clean all

# ==========================
# FINAL IMAGE
# ==========================

FROM fedora:42

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Create user
RUN set -ex && \
    dnf install -y shadow-utils && \
    groupadd -g 1001 hasura && \
    useradd -m -u 1001 -g hasura hasura && \
    dnf remove -y shadow-utils && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# Install pg_dump
COPY --from=pg_dump_source /usr/bin/pg_dump /usr/bin/pg_dump

# graphql-engine is built on ubuntu, so the binary links to the debian version of pcre so(libpcre.so.3).
# here, we are creating a symlink to libpcre.so.1. we did this in the centos images as well:
# https://github.com/hasura/graphql-engine-mono/blob/02dc61f05e06f46c193be3685abbef9c8535edef/packaging/graphql-engine-base/centos.dockerfile#L45
RUN ln -s /usr/lib64/libpcre.so.1 /usr/lib64/libpcre.so.3

# Install runtime deps
RUN dnf -y update \
    && dnf install -y \
       krb5-libs \
       libpq \
       numactl-libs \
       libicu \
       unixODBC \
       curl \
       nc \
    && dnf clean all \
    && rm -rf /var/cache/dnf
	
# Copy built binary
COPY --from=build /tmp/graphql-engine/graphql-engine /usr/local/bin/graphql-engine

HEALTHCHECK --start-period=10s CMD curl -f http://localhost:8080/healthz || exit 1

CMD ["/usr/local/bin/graphql-engine", "serve"]
