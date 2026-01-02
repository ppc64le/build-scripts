# --- STAGE 1: Prisma Engine Builder ---
FROM registry.access.redhat.com/ubi9/python-312:latest AS prisma-builder

###Required Labels
LABEL name="litellm-pgvector" maintainer="purva.naik1@ibm.com" 

USER root

RUN dnf install -y \
    gcc gcc-c++ \
    make \
    pkg-config \
    openssl-devel \
    clang \
    git \
    unzip && \
    dnf clean all

RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v25.1/protoc-25.1-linux-ppcle_64.zip && \
    unzip protoc-25.1-linux-ppcle_64.zip -d /usr/local && \
    chmod +x /usr/local/bin/protoc && \
    rm protoc-25.1-linux-ppcle_64.zip

ENV PROTOC=/usr/local/bin/protoc

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app
RUN git clone --depth 1 --branch 5.17.0 https://github.com/prisma/prisma-engines.git .

RUN echo -e '\n[patch.crates-io]\nring = { git = "https://github.com/ibm/ring.git", branch = "ppc-0.16.20" }' >> Cargo.toml

ENV CC=clang
RUN . "$HOME/.cargo/env" && cargo build --release

# --- STAGE 2: Litellm-Pgvector Python Builder (Dependencies) ---
FROM registry.access.redhat.com/ubi9/python-312:latest AS python-builder

WORKDIR /app
USER root

RUN dnf install -y gcc git  postgresql-devel libatomic && dnf clean all
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN git clone https://github.com/BerriAI/litellm-pgvector.git .
RUN sed -i 's/vector(1536)/vector/g' prisma/schema.prisma
RUN pip install --no-cache-dir -r requirements.txt \
    --prefer-binary \
    --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux
RUN pip install --no-cache-dir --upgrade prisma

# --- STAGE 3: Runtime ---
FROM registry.access.redhat.com/ubi9/python-312:latest
USER root
WORKDIR /app

RUN dnf install -y postgresql-libs libatomic && dnf clean all

COPY --from=python-builder /opt/venv /opt/venv
COPY --from=python-builder /app /app

RUN mkdir -p /usr/local/lib/prisma
COPY --from=prisma-builder /app/target/release/query-engine /usr/local/lib/prisma/
COPY --from=prisma-builder /app/target/release/schema-engine /usr/local/lib/prisma/
RUN chmod +x /usr/local/lib/prisma/*

ENV PRISMA_QUERY_ENGINE_BINARY=/usr/local/lib/prisma/query-engine
ENV PRISMA_CLI_QUERY_ENGINE_TYPE=binary
ENV PRISMA_SCHEMA_ENGINE_BINARY=/usr/local/lib/prisma/schema-engine
ENV PYTHONPATH=/app
ENV PATH="/opt/venv/bin:${PATH}"
RUN prisma generate

EXPOSE 8000
CMD sh -c "prisma db push && uvicorn main:app --host 0.0.0.0 --port 8000"
