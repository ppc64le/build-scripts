# ============================================================
# Stage 1: Builder (Power9 / UBI 9.6)
# ============================================================
FROM registry.access.redhat.com/ubi9/ubi:9.6 AS builder
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1
WORKDIR /build

# Install system basics
RUN yum -y update && \
    yum -y install --allowerasing \
        bash git wget curl tar xz gzip bzip2 which sudo && \
    yum clean all

# Download official build script and patch
RUN wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/l/langflow/langflow_v1.7.3.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/l/langflow/langflow_v1.7.3_ubi9.6.sh && \
    chmod +x langflow_v1.7.3_ubi9.6.sh

# Execute the build script (import test fails because dependencies are not yet installed due to --no-deps)
RUN ./langflow_v1.7.3_ubi9.6.sh 1.7.3 || true

# Now install ALL the missing dependencies that were skipped due to --no-deps
# These versions match the confirmed working configuration
WORKDIR /build/langflow
RUN python3.12 -m pip install \
    'lfx~=0.2.1' \
    'fastapi>=0.128.5,<1.0.0' \
    'httpx[http2]>=0.27,<1.0.0' \
    'aiofile>=3.9.0,<4.0.0' \
    'uvicorn>=0.30.0,<1.0.0' \
    'gunicorn>=22.0.0,<23.0.0' \
    'langchain>=0.3.27,<0.4.0' \
    'langchain-community>=0.3.31,<0.4.0' \
    'langchain-core>=0.3.83,<0.4.0' \
    'langchainhub>=0.1.21,<0.2.0' \
    'loguru>=0.7.1,<1.0.0' \
    'structlog>=25.4.0,<26.0.0' \
    'rich>=13.7.0,<14.0.0' \
    'langchain-experimental>=0.3.4,<0.4.0' \
    'sqlmodel>=0.0.32,<1.0.0' \
    'pydantic>=2.12.5,<3.0.0' \
    'pydantic-settings>=2.12.0,<3.0.0' \
    'SQLAlchemy>=2.0.23,<3.0.0' \
    'email-validator>=2.0.0' \
    'typer>=0.13.0,<1.0.0' \
    'cachetools>=6.0.0' \
    'platformdirs>=4.2.0,<5.0.0' \
    'python-multipart>=0.0.12,<1.0.0' \
    'orjson==3.10.15' \
    'alembic>=1.13.0,<2.0.0' \
    'passlib>=1.7.4,<2.0.0' \
    'pillow>=11.1.0,<12.0.0' \
    'docstring-parser>=0.16,<1.0.0' \
    'python-jose>=3.3.0,<4.0.0' \
    'pandas==2.2.3' \
    'multiprocess>=0.70.14,<1.0.0' \
    'duckdb>=1.0.0,<2.0.0' \
    'python-docx>=1.1.0,<2.0.0' \
    'nest-asyncio>=1.6.0,<2.0.0' \
    'emoji>=2.12.0,<3.0.0' \
    'cryptography>=43.0.1,<44.0.0' \
    'asyncer>=0.0.5,<1.0.0' \
    'pyperclip>=1.8.2,<2.0.0' \
    'uncurl>=0.0.11,<1.0.0' \
    'sentry-sdk[fastapi,loguru]>=2.5.1,<3.0.0' \
    'chardet>=5.2.0,<6.0.0' \
    'firecrawl-py>=1.0.16,<2.0.0' \
    'opentelemetry-api>=1.25.0,<2.0.0' \
    'opentelemetry-sdk>=1.25.0,<2.0.0' \
    'opentelemetry-exporter-prometheus>=0.46b0,<1.0.0' \
    'opentelemetry-instrumentation-fastapi>=0.46b0,<1.0.0' \
    'prometheus-client>=0.20.0,<1.0.0' \
    'aiofiles>=24.1.0,<25.0.0' \
    'nanoid>=2.0.0,<3.0.0' \
    'filelock>=3.20.1,<4.0.0' \
    'grandalf>=0.8.0,<1.0.0' \
    'spider-client>=0.0.27,<1.0.0' \
    'diskcache>=5.6.3,<6.0.0' \
    'clickhouse-connect==0.7.19' \
    'assemblyai>=0.33.0,<1.0.0' \
    'fastapi-pagination>=0.13.1,<1.0.0' \
    'defusedxml>=0.7.1,<1.0.0' \
    'pypdf>=6.4.0,<7.0.0' \
    'validators>=0.34.0,<1.0.0' \
    'networkx>=3.4.2,<4.0.0' \
    'json-repair>=0.30.3,<1.0.0' \
    'mcp>=1.17.0,<2.0.0' \
    'aiosqlite>=0.20.0,<1.0.0' \
    'greenlet>=3.1.1,<4.0.0' \
    'jsonquerylang>=1.1.1,<2.0.0' \
    'elevenlabs==1.58.1' \
    'scipy>=1.15.2,<2.0.0' \
    'ibm-watsonx-ai>=1.3.1,<2.0.0' \
    'langchain-ibm>=0.3.8,<1.0.0' \
    'trustcall>=0.0.38,<1.0.0' \
    'langchain-chroma>=0.1.4,<1.0.0' \
    --extra-index-url="https://wheels.developerfirst.ibm.com/ppc64le/linux" \
    --prefer-binary

# Install LFX engine
WORKDIR /build/langflow/src/lfx
RUN python3.12 -m pip install . --no-deps

# ============================================================
# Stage 2: Runtime Image
# ============================================================
FROM registry.access.redhat.com/ubi9/ubi:9.6 AS runtime

# Install Python 3.12 and runtime dependencies
RUN yum -y update && \
    yum -y install python3.12 gcc-toolset-13 git && \
    yum clean all

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/rh/gcc-toolset-13/root/usr/bin:/usr/local/bin:/usr/bin:/bin \
    LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:/opt/rh/gcc-toolset-13/root/usr/lib64

WORKDIR /app

COPY --from=builder /usr/local /usr/local
COPY --from=builder /opt/rh /opt/rh
COPY --from=builder /usr/lib64 /usr/lib64
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/lib/python3.12 /usr/lib/python3.12
COPY --from=builder /usr/lib64/python3.12 /usr/lib64/python3.12

EXPOSE 7860

CMD ["langflow", "run", "--host", "0.0.0.0", "--port", "7860"]
