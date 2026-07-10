############################################################
# STAGE 1 - Builder
############################################################

ARG BASE_UBI_IMAGE_TAG=9.8

FROM registry.access.redhat.com/ubi9/ubi-minimal:${BASE_UBI_IMAGE_TAG} AS builder

ARG AGENTSTACK_VERSION=v0.4.3
ARG POSTGRES_VERSION=16.4
ARG PGVECTOR_VERSION=v0.7.4
ARG RELEASE_VERSION=v0.4.3

ENV POSTGRES_INSTALL_DIR=/local/apps/postgresql/pgsql164
ENV POSTGRES_DATA_DIR=/local/apps/postgresql/pgsql164/data

ENV PATH="/root/.local/bin:${PATH}" \
    UV_HTTP_TIMEOUT=300 \
    UV_HTTP_RETRIES=5 \
    GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 \
    GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

############################################################
# Build dependencies
############################################################

RUN microdnf update -y && \
    microdnf install -y \
        git \
        tar \
        wget \
        gcc \
        gcc-c++ \
        make \
        cmake \
        clang \
        rust \
        cargo \
        python3.12 \
        python3.12-devel \
        openssl-devel \
        libffi-devel \
        zlib-devel \
        readline \
        postgresql \
        postgresql-devel \
        libpq-devel \
        libicu \
        libicu-devel \
        libjpeg-turbo \
        libjpeg-turbo-devel \
        freetype-devel \
        libpng-devel \
        pkgconfig \
        findutils \
        ca-certificates && \
    microdnf clean all

############################################################
# Install uv
############################################################

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

############################################################
# Build PostgreSQL
############################################################

WORKDIR /tmp

RUN wget https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.gz && \
    tar xf postgresql-${POSTGRES_VERSION}.tar.gz

WORKDIR /tmp/postgresql-${POSTGRES_VERSION}

RUN ./configure \
      --without-readline \
      --prefix=${POSTGRES_INSTALL_DIR} \
      --with-pgport=5433 && \
    make -j"$(nproc)" && \
    make install

############################################################
# Build pgvector
############################################################

WORKDIR /tmp

RUN git clone https://github.com/pgvector/pgvector.git

WORKDIR /tmp/pgvector

RUN git checkout ${PGVECTOR_VERSION}

RUN sed -i \
    "s|pg_config|${POSTGRES_INSTALL_DIR}/bin/pg_config|g" \
    Makefile

RUN make -j"$(nproc)" && \
    make install

############################################################
# Clone AgentStack
############################################################

WORKDIR /app

RUN git clone https://github.com/i-am-bee/agentstack.git .

RUN git fetch --all --tags && \
    git checkout ${AGENTSTACK_VERSION}

############################################################
# Apply patch
############################################################

#RUN wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/agentstack/agentstack_v0.4.3.patch

RUN wget -O /tmp/agentstack.patch https://raw.githubusercontent.com/Simran-Sirsat/build-scripts/agentstack/a/agentstack/agentstack_v0.4.3.patch && \
    git apply /tmp/agentstack.patch

############################################################
# Build AgentStack Server
############################################################

WORKDIR /app/apps/agentstack-server

RUN uv lock --upgrade

RUN UV_COMPILE_BYTECODE=1 \
    HOME=/tmp \
    uv sync

############################################################
# Configure Server
############################################################

RUN cp template.env .env && \
    echo "AUTH__DISABLE_AUTH=true" >> .env && \
    echo "OIDC__DISABLE_OIDC=true" >> .env && \
    echo "PERSISTENCE__DB_URL=postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack" >> .env

############################################################
# Cleanup builder
############################################################

RUN rm -rf \
        /root/.cache \
        /root/.cargo/registry \
        /root/.cargo/git \
        /app/.git \
        /tmp/*

############################################################
# STAGE 2 - Runtime
############################################################

FROM registry.access.redhat.com/ubi9/ubi-minimal:${BASE_UBI_IMAGE_TAG}

ARG RELEASE_VERSION=v0.4.3

ENV POSTGRES_INSTALL_DIR=/local/apps/postgresql/pgsql164
ENV POSTGRES_DATA_DIR=/local/apps/postgresql/pgsql164/data

ENV DATABASE_URL=postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack
ENV PERSISTENCE__DB_URL=postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack

ENV PRODUCTION_MODE=True \
    RELEASE_VERSION=${RELEASE_VERSION} \
    PATH="${POSTGRES_INSTALL_DIR}/bin:${PATH}"

############################################################
# Runtime dependencies
############################################################

RUN microdnf update -y && \
    microdnf install -y \
        python3.12 \
        postgresql \
        libpq \
        openssl \
        readline \
        zlib \
        libicu \
        libjpeg-turbo \
        freetype \
        libpng \
        ca-certificates && \
    microdnf clean all

############################################################
# Copy PostgreSQL
############################################################

COPY --from=builder \
    ${POSTGRES_INSTALL_DIR} \
    ${POSTGRES_INSTALL_DIR}

############################################################
# Copy only required application
############################################################

COPY --from=builder \
    /app/apps/agentstack-sdk-py \
    /app/apps/agentstack-sdk-py

COPY --from=builder \
    /app/apps/agentstack-server \
    /app/apps/agentstack-server

############################################################
# Remove non-runtime files
############################################################

RUN rm -rf \
    /app/apps/agentstack-sdk-py/tests \
    /app/apps/agentstack-sdk-py/examples \
    /tmp/*

############################################################
# Runtime
############################################################

WORKDIR /app/apps/agentstack-server

CMD ["/app/apps/agentstack-server/.venv/bin/agentstack-server"]