# ============================================================
# 1. Builder Stage
# ============================================================
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS builder

ENV SEARXNG_PATH=/usr/local/searxng \
    SEARXNG_USER=searxng \
    PYTHONUNBUFFERED=1 \
    LANG=en_US.UTF-8 \
    LD_LIBRARY_PATH=/usr/local/lib \
    SEARXNG_DISABLE_GIT_INFO=1

# Install build tools and Python
RUN dnf -y update && \
    dnf -y install \
        git \
        python3.12 \
        python3.12-pip \
        python3.12-devel \
        gcc \
        gcc-c++ \
        make \
        openssl-devel \
        wget \
        which \
        shadow-utils && \
    dnf clean all

RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 20

# ------------------------------------------------------------
# Build SQLite 3.51
# ------------------------------------------------------------
RUN cd /tmp && \
    wget https://www.sqlite.org/2025/sqlite-autoconf-3510000.tar.gz && \
    tar xzf sqlite-autoconf-3510000.tar.gz && \
    cd sqlite-autoconf-3510000 && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/sqlite.conf && \
    ldconfig

# ------------------------------------------------------------
# Clone SearXNG
# ------------------------------------------------------------
RUN git clone https://github.com/searxng/searxng.git ${SEARXNG_PATH}
WORKDIR ${SEARXNG_PATH}

# ------------------------------------------------------------
# Install Python Dependencies
# ------------------------------------------------------------
RUN python3 -m pip install --upgrade pip setuptools wheel --no-cache-dir && \
    python3 -m pip install \
        msgspec uvloop orjson pyyaml requests uwsgi pybind11 httpx \
        --no-cache-dir --prefer-binary && \
    python3 -m pip install -e . \
        --use-pep517 \
        --no-build-isolation \
        --no-cache-dir \
        --prefer-binary

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------
RUN find /usr -type d -name "__pycache__" -exec rm -rf {} + || true && \
    rm -rf /root/.cache /tmp/*

# ============================================================
# 2. Runtime Stage
# ============================================================
FROM registry.access.redhat.com/ubi9-minimal:9.7 AS runtime

ENV SEARXNG_PATH=/usr/local/searxng \
    SEARXNG_USER=searxng \
    LANG=en_US.UTF-8 \
    SEARXNG_PORT=8888 \
    SEARXNG_BIND_ADDRESS=0.0.0.0 \
    LD_LIBRARY_PATH=/usr/local/lib \
    LD_PRELOAD=/usr/local/lib/libsqlite3.so \
    SEARXNG_DISABLE_GIT_INFO=1


# Install runtime deps
RUN microdnf install -y \
        python3.12 \
        python3.12-pip \
        git && \
    microdnf clean all && \
    rm -rf /var/cache/*

RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 20

# ------------------------------------------------------------
# Copy artifacts
# ------------------------------------------------------------
COPY --from=builder /usr/local /usr/local

# ------------------------------------------------------------
# Ensure runtime linker sees SQLite 3.51
# ------------------------------------------------------------
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/sqlite.conf && ldconfig

# ------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8888
ENTRYPOINT ["entrypoint.sh"]

# ------------------------------------------------------------
# Start SearXNG via uWSGI (RE
CMD ["uwsgi", \
     "--http", "0.0.0.0:8888", \
     "--wsgi-file", "/usr/local/searxng/searx/webapp.py", \
     "--callable", "app", \
     "--master", \
     "--processes", "2", \
     "--threads", "2", \
     "--enable-threads", \
     "--die-on-term"]