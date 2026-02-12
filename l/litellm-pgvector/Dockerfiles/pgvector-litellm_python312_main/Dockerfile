# --- STAGE 1: Prisma Engine Builder ---
FROM registry.access.redhat.com/ubi9/python-312:latest AS prisma-builder

LABEL name="litellm-pgvector" maintainer="purva.naik1@ibm.com" 

USER root

RUN dnf update -y && dnf install -y \
    gcc gcc-c++ make pkg-config openssl-devel clang git unzip && \
    dnf clean all && \
    curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v25.1/protoc-25.1-linux-ppcle_64.zip && \
    unzip protoc-25.1-linux-ppcle_64.zip -d /usr/local && \
    chmod +x /usr/local/bin/protoc && \
    rm protoc-25.1-linux-ppcle_64.zip && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PROTOC=/usr/local/bin/protoc \
    PATH="/root/.cargo/bin:${PATH}" \
    CC=clang

WORKDIR /app

RUN git clone --depth 1 --branch 5.17.0 https://github.com/prisma/prisma-engines.git . && \
    echo -e '\n[patch.crates-io]\nring = { git = "https://github.com/ibm/ring.git", branch = "ppc-0.16.20" }' >> Cargo.toml && \
    . "$HOME/.cargo/env" && cargo build --release

# --- STAGE 2: Litellm-Pgvector Python Builder ---
FROM registry.access.redhat.com/ubi9/python-312:latest AS python-builder

WORKDIR /app
USER root

ENV PATH="/opt/venv/bin:$PATH"

RUN dnf update -y && dnf install -y gcc git postgresql-devel libatomic && dnf clean all && \
    python -m venv /opt/venv && \
    git clone https://github.com/BerriAI/litellm-pgvector.git . && \
    sed -i 's/vector(1536)/vector/g' prisma/schema.prisma && \
    pip install --no-cache-dir -r requirements.txt --prefer-binary \
    --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux && \
    pip install --no-cache-dir --upgrade prisma fastapi python-multipart

# --- STAGE 3: Runtime ---
FROM registry.access.redhat.com/ubi9/python-312:latest
USER root
WORKDIR /app

ENV PRISMA_QUERY_ENGINE_BINARY=/usr/local/lib/prisma/query-engine \
    PRISMA_CLI_QUERY_ENGINE_TYPE=binary \
    PRISMA_SCHEMA_ENGINE_BINARY=/usr/local/lib/prisma/schema-engine \
    PYTHONPATH=/app \
    PATH="/opt/venv/bin:${PATH}"

RUN dnf update -y && dnf install -y postgresql-libs libatomic && dnf clean all

COPY --from=python-builder /opt/venv /opt/venv
COPY --from=python-builder /app /app
COPY --from=prisma-builder /app/target/release/query-engine /usr/local/lib/prisma/
COPY --from=prisma-builder /app/target/release/schema-engine /usr/local/lib/prisma/

RUN chmod +x /usr/local/lib/prisma/* && prisma generate

EXPOSE 8000
CMD sh -c "prisma db push && uvicorn main:app --host 0.0.0.0 --port 8000"
