# --- STAGE 1: Rust Builder (Prisma Engines) ---
FROM rust:1.81-slim AS prisma-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config protobuf-compiler \
    libssl-dev \
    clang \
    git && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone --depth 1 --branch 5.17.0 https://github.com/prisma/prisma-engines.git .

RUN echo '\
[patch.crates-io]\n\
ring = { git = "https://github.com/ibm/ring.git", branch = "ppc-0.16.20" }\n\
' >> Cargo.toml

ENV CC=clang
RUN cargo build --release


# --- STAGE 2: Python Builder (Dependencies) ---
FROM python:3.12-slim AS python-builder

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git curl libpq-dev && rm -rf /var/lib/apt/lists/*

# Clone app and install dependencies to a local folder
RUN git clone https://github.com/BerriAI/litellm-pgvector.git .
RUN sed -i 's/vector(1536)/vector/g' prisma/schema.prisma

# Install python packages to a prefix to easily copy them later
RUN pip install --no-cache-dir --prefix=/install \
    -r requirements.txt \
    --prefer-binary \
    --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux
RUN pip install --no-cache-dir --prefix=/install --upgrade prisma


# --- STAGE 3: Runtime ---
FROM python:3.12-slim

WORKDIR /app

# Install only runtime system libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    postgresql-client libatomic1 \
    curl && rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder
COPY --from=python-builder /install /usr/local
# Copy Application code
COPY --from=python-builder /app /app

# Copy Prisma engines from Rust builder
RUN mkdir -p /usr/local/lib/prisma
COPY --from=prisma-builder /app/target/release/*-engine /usr/local/lib/prisma/
RUN chmod +x /usr/local/lib/prisma/*

# Environment Variables
ENV PYTHONPATH=/app
ENV PRISMA_QUERY_ENGINE_BINARY=/usr/local/lib/prisma/query-engine
ENV PRISMA_CLI_QUERY_ENGINE_TYPE=binary

# Generate Prisma client in the final runtime
RUN prisma generate
ENV PRISMA_SCHEMA_ENGINE_BINARY=/usr/local/lib/prisma/schema-engine
EXPOSE 8000

CMD sh -c "prisma db push && uvicorn main:app --host 0.0.0.0 --port 8000"

