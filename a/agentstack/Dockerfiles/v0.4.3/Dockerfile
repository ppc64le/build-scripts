# Dockerfile for chat agent
############################################################
# STAGE 1 - Builder
############################################################

ARG BASE_UBI_IMAGE_TAG=9.8

FROM registry.access.redhat.com/ubi9/ubi-minimal:${BASE_UBI_IMAGE_TAG} AS builder

ARG AGENTSTACK_VERSION=v0.4.3
ARG RELEASE_VERSION=v0.4.3

ENV PATH="/root/.local/bin:${PATH}" \
    GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 \
    GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1 \
    CXXFLAGS="-std=c++17"

############################################################
# Build dependencies
############################################################

RUN microdnf update -y && \
    microdnf install -y \
        git \
        tar \
        gcc \
        gcc-c++ \
        cmake \
        make \
        python3.12 \
        python3.12-devel \
        openssl-devel \
        libffi-devel \
        zlib-devel \
        rust \
        cargo \
        pkgconfig \
        findutils \
        wget \
        ca-certificates && \
    microdnf clean all

############################################################
# Install uv
############################################################

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

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

RUN wget -O /tmp/agentstack.patch https://raw.githubusercontent.com/Simran-Sirsat/build-scripts/agentstack/a/agentstack-chat/agentstack_v0.4.3.patch && \
    git apply /tmp/agentstack.patch

############################################################
# Build Chat Agent
############################################################

WORKDIR /app/agents/chat

RUN uv lock --upgrade

RUN UV_COMPILE_BYTECODE=1 \
    HOME=/tmp \
    uv sync

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

ENV PRODUCTION_MODE=True \
    RELEASE_VERSION=${RELEASE_VERSION}

############################################################
# Runtime dependencies
############################################################

RUN microdnf update -y && \
    microdnf install -y \
        python3.12 \
        ca-certificates && \
    microdnf clean all

############################################################
# Copy application
############################################################

COPY --from=builder \
    /app/apps/agentstack-sdk-py \
    /app/apps/agentstack-sdk-py

COPY --from=builder \
    /app/agents/chat \
    /app/agents/chat

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

WORKDIR /app/agents/chat

CMD ["/app/agents/chat/.venv/bin/server"]
