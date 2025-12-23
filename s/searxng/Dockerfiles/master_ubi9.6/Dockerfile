# 1. Builder Stage
FROM registry.access.redhat.com/ubi9/ubi:9.6 AS builder

ENV SEARXNG_PATH=/usr/local/searxng \
    SEARXNG_USER=searxng \
    PYTHONUNBUFFERED=1 \
    LANG=en_US.UTF-8

# Install ONLY build tools
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

# Python alternatives
RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 20

# Build SQLite 3.51
RUN cd /tmp && \
    wget https://www.sqlite.org/2025/sqlite-autoconf-3510000.tar.gz && \
    tar xzf sqlite-autoconf-3510000.tar.gz && \
    cd sqlite-autoconf-3510000 && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && make install

# Clone SearXNG 
RUN git clone https://github.com/searxng/searxng.git ${SEARXNG_PATH}
WORKDIR ${SEARXNG_PATH}

############ Install Python Dependencies (Optimized) ############

RUN python3 -m pip install --upgrade pip setuptools wheel --no-cache-dir && \
    python3 -m pip install msgspec uvloop orjson pyyaml requests uwsgi pybind11 httpx \
        --no-cache-dir --prefer-binary && \
    python3 -m pip install -e . \
        --use-pep517 \
        --no-build-isolation \
        --no-cache-dir \
        --prefer-binary

# Remove Python cache and build leftover
RUN find /usr -type d -name "__pycache__" -exec rm -rf {} + || true && \
    rm -rf /root/.cache || true && \
    rm -rf /tmp/*




# 2. Runtime Stage (Slim)
FROM registry.access.redhat.com/ubi9-minimal:9.6 AS runtime
ENV SEARXNG_PATH=/usr/local/searxng \
    SEARXNG_USER=searxng \
    LANG=en_US.UTF-8

ENV SEARXNG_PORT=8888 \
    SEARXNG_BIND_ADDRESS=0.0.0.0

# Install only required runtime libs
RUN microdnf install -y \
        git \
        python3.12 \
        python3.12-pip && \
    microdnf clean all && \
    rm -rf /var/cache/*

RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 20


# Copy only what is necessary
COPY --from=builder /usr/local /usr/local
#COPY --from=builder /usr/local/searxng /usr/local/searxng

# ENTRYPOINT
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8888
ENTRYPOINT ["entrypoint.sh"]

CMD ["/bin/sh", "-c", "python3 ${SEARXNG_PATH}/searx/webapp.py"]
