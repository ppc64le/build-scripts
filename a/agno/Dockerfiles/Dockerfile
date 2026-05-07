# stage 1 - builder
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS builder

WORKDIR /build

ARG AGNO_VERSION=v2.6.3
ENV IBM_WHEEL_INDEX=https://wheels.developerfirst.ibm.com/ppc64le/linux

# Install System Dependencies
RUN yum install -y \
    git make wget python3.12 python3.12-devel python3.12-pip \
    gcc gcc-c++ gcc-gfortran \
    openssl openssl-devel \
    libffi libffi-devel pkgconf-pkg-config \
    autoconf automake libtool m4 \
    cmake unzip \
    openblas-devel \
    zlib-devel bzip2-devel xz-devel libjpeg-turbo-devel \
    && yum clean all && rm -rf /var/cache/yum

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install uv
RUN python3.12 -m pip install --upgrade pip && \
    python3.12 -m pip install uv
ENV PATH="/root/.local/bin:/usr/local/bin:${PATH}"

# Clone Agno
RUN git clone https://github.com/agno-agi/agno
WORKDIR /build/agno

# Checkout version
RUN git checkout ${AGNO_VERSION}
COPY agno_2.6.3.patch /build/agno_2.6.3.patch
RUN git apply /build/agno_2.6.3.patch

# Create virtual environment
RUN uv venv .venv --python python3.12
RUN .venv/bin/python -m ensurepip
RUN .venv/bin/python -m pip install --upgrade pip setuptools wheel
ENV VENV_PYTHON=/build/agno/.venv/bin/python

# Install base deps
RUN uv pip install -r libs/agno/requirements.txt \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match \
    --no-cache-dir

RUN uv pip install -e libs/agno[dev] \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match \
    --no-cache-dir

RUN uv pip install -r libs/agno_infra/requirements.txt \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match \
    --no-cache-dir

RUN uv pip install -e libs/agno_infra[dev] \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match \
    --no-cache-dir

# Build SQLite 3.45
RUN wget https://www.sqlite.org/2024/sqlite-autoconf-3450000.tar.gz && \
    tar xzf sqlite-autoconf-3450000.tar.gz && \
    cd sqlite-autoconf-3450000 && \
    ./configure --prefix=/usr/local --enable-shared && \
    make -j$(nproc) && \
    make install && \
    cd /build && \
    rm -rf sqlite-autoconf-3450000*

# Configure SQLite environment for builder stage
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/sqlite3.conf && \
    ldconfig

RUN rm -rf /root/.cache \
           /root/.local/share/uv \
           /tmp/*

RUN find /build/agno/.venv -type f -name '*.pyc' -delete && \
    find /build/agno/.venv -type d -name '__pycache__' -exec rm -rf {} + && \
    rm -rf /build/agno/.venv/share \
           /build/agno/.venv/include

# Stage 2 - Runtime 
FROM registry.access.redhat.com/ubi9/ubi:9.7

WORKDIR /build/agno

RUN yum install -y \
    gcc gcc-c++ make \
    python3.12-devel \
    libffi-devel \
    openssl-devel \
    zlib-devel \
    bzip2-devel \
    xz-devel \
    openblas-devel \
    pkgconfig \
    git \
    && yum clean all

# Copy entire /usr/local from builder (includes SQLite 3.45 and uv)
COPY --from=builder /usr/local /usr/local

# Configure linker for SQLite libraries
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/sqlite3.conf && \
    ldconfig

COPY --from=builder /build/agno /build/agno

ENV PATH="/build/agno/.venv/bin:$PATH"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]