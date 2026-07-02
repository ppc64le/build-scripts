############################################################
# STAGE 1 - Builder
############################################################

FROM registry.access.redhat.com/ubi9/ubi:9.7 AS builder

ARG AGENTSTACK_VERSION=v0.4.3
ARG POSTGRES_VERSION=16.4
ARG PGVECTOR_VERSION=v0.7.4
ARG GO_VERSION=1.26.4

ENV POSTGRES_INSTALL_DIR=/local/apps/postgresql/pgsql164
ENV POSTGRES_DATA_DIR=/local/apps/postgresql/pgsql164/data
ENV WORKDIR=/root/agentstack

ENV PACKAGE_NAME=agentstack
ENV PACKAGE_VERSION=v0.4.3

WORKDIR /root

############################################################
# System packages
############################################################

RUN mkdir -p /tmp && chmod 1777 /tmp

#RUN dnf update -y && \
 #   dnf install -y dnf-plugins-core wget && \
 #   dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os && \
 #   dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os && \
 #   dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os && \
 #   rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256;

RUN dnf install -y \
    wget \
    git \
    gcc \
    gcc-c++ \
    make \
    cmake \
    patch \
    clang \
    clang-devel \
    llvm-devel \
    curl-devel \
    readline \
    openssl-devel \
    pkgconfig \
    ca-certificates \
    python3 \
    python3-devel \
    libpq-devel \
    postgresql \
    postgresql-devel \
    zlib-devel \
    libicu-devel \
    libjpeg-turbo-devel \
    freetype-devel \
    libpng-devel \
    dnf-plugins-core \
    rust \
    cargo \
 && dnf clean all

RUN dnf update -y acl attr expat glib2 gnutls libcap openssl && \
    dnf remove -y vim-minimal java-17-openjdk-headless 2>/dev/null || true && \
    dnf clean all

############################################################
# Docker CLI
############################################################

RUN dnf config-manager \
        --add-repo=https://download.docker.com/linux/centos/docker-ce.repo || true && \
    dnf install -y \
        docker-ce-cli \
        docker-buildx-plugin \
        docker-compose-plugin

############################################################
# Rust
############################################################

#RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

#ENV PATH="/root/.cargo/bin:${PATH}"

############################################################
# uv
############################################################

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/root/.local/bin:${PATH}"

############################################################
# Go
############################################################

RUN wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm -f go${GO_VERSION}.linux-ppc64le.tar.gz

ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH="${GOROOT}/bin:${GOPATH}/bin:${PATH}"

############################################################
# gRPC Build Environment
############################################################

ENV GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
ENV GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

############################################################
# PostgreSQL
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
# pgvector
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

WORKDIR /root

RUN git clone https://github.com/i-am-bee/agentstack.git

WORKDIR /root/agentstack

RUN wget https://raw.githubusercontent.com/Simran-Sirsat/build-scripts/agentstack/a/agentstack/agentstack_${PACKAGE_VERSION}.patch -O /root/agentstack.patch
#RUN wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/a/agentstack/agentstack_${PACKAGE_VERSION}.patch -O /root/agentstack.patch


RUN git fetch --all --tags && \
    git checkout ${AGENTSTACK_VERSION} && \
    git apply /root/agentstack.patch


############################################################
# Create ONE shared virtual environment
############################################################

WORKDIR /root/agentstack

# Create single venv for entire project
RUN uv python install 3.12 && \
    uv venv /root/.venv --python 3.12

# Activate it globally
ENV VIRTUAL_ENV=/root/.venv
ENV PATH="/root/.venv/bin:$PATH"

############################################################
# Build SDK
############################################################

WORKDIR /root/agentstack/apps/agentstack-sdk-py

RUN rm -f uv.lock && \
    uv lock && \
    uv sync

############################################################
# Build CLI
############################################################

WORKDIR /root/agentstack/apps/agentstack-cli

RUN rm -f uv.lock && \
    uv lock && \
    uv sync

############################################################
# Build Server
############################################################

WORKDIR /root/agentstack/apps/agentstack-server

RUN rm -f uv.lock && \
    uv lock && \
    uv sync && \
    uv add "pydantic==2.11.7" && \
    uv sync

############################################################
# Build Chat Agent
############################################################

WORKDIR /root/agentstack/agents/chat

RUN rm -f uv.lock && \
    uv lock && \
    uv sync

############################################################
# Build Form Agent
############################################################

WORKDIR /root/agentstack/agents/form

RUN rm -f uv.lock && \
    uv lock && \
    uv sync

############################################################
# Build RAG Agent
############################################################

WORKDIR /root/agentstack/agents/rag

RUN rm -f uv.lock && \
    uv lock && \
    uv sync

############################################################
# FIX VULNERABILITIES ONCE FOR ALL COMPONENTS
############################################################

RUN uv pip install --upgrade pip>=24.3.1 urllib3>=2.7.0 && \
    (uv pip list | grep -q pyo3 && uv pip install --upgrade pyo3>=0.29.0 || true)

############################################################
# Server configuration
############################################################

WORKDIR /root/agentstack/apps/agentstack-server

RUN cp template.env .env && \
    echo "AUTH__DISABLE_AUTH=true" >> .env && \
    echo "OIDC__DISABLE_OIDC=true" >> .env && \
    echo "PERSISTENCE__DB_URL=postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack" >> .env

ENV DATABASE_URL=postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack
ENV PERSISTENCE__DB_URL=postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack
RUN rm -rf /var/cache/dnf /var/tmp/*
############################################################
# STAGE 2 - Runtime image
############################################################

FROM registry.access.redhat.com/ubi9/ubi:9.7

ARG POSTGRES_VERSION=16.4

ENV POSTGRES_INSTALL_DIR=/local/apps/postgresql/pgsql164
ENV POSTGRES_DATA_DIR=/local/apps/postgresql/pgsql164/data
ENV WORKDIR=/root/agentstack

WORKDIR /root

############################################################
# Runtime dependencies only
############################################################

RUN mkdir -p /tmp && chmod 1777 /tmp

#RUN dnf install -y dnf-plugins-core wget && \
 #   dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os && \
 #   dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os && \
 #   dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os && \
 #   rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256; 


RUN dnf update -y && \
    dnf install -y \
    python3 \
    libpq-devel \
    postgresql \
    postgresql-devel \
    openssl-devel \
    readline \
    zlib-devel \
    libicu-devel \
    libjpeg-turbo-devel \
    freetype-devel \
    libpng-devel \
 && dnf clean all

RUN rm -rf /var/cache/dnf /var/tmp/*

############################################################
# Copy tools
############################################################

COPY --from=builder /root/.cargo /root/.cargo
COPY --from=builder /root/.local /root/.local
COPY --from=builder /usr/local/go /usr/local/go

COPY --from=builder /root/.venv /root/.venv

ENV PATH="/root/.cargo/bin:/root/.local/bin:/usr/local/go/bin:/root/go/bin:${PATH}"
ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go

############################################################
# Copy PostgreSQL + pgvector
############################################################

COPY --from=builder ${POSTGRES_INSTALL_DIR} ${POSTGRES_INSTALL_DIR}

############################################################
# Copy AgentStack
############################################################

COPY --from=builder /root/agentstack /root/agentstack

############################################################
# Runtime environment
############################################################

ENV DATABASE_URL=postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack
ENV PERSISTENCE__DB_URL=postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack

WORKDIR /root/agentstack/apps/agentstack-server

CMD ["/bin/bash"]