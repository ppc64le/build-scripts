FROM registry.access.redhat.com/ubi9/ubi:9.3 as build-stage

# Install Python 3.12 and dependencies
RUN dnf install -y \
        gcc \
        gcc-c++ \
        rust \
        cargo \
        make \
        libcurl-devel \
        bzip2-devel \
        openssl-devel \
        sqlite \
        libffi-devel \
        zlib-devel \
        xz \
        sqlite-devel \
        openblas-devel \
        bzip2 \
        xz \
        tar \
        postgresql-devel \
        wget && \
    yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel wget xz zlib-devel cmake openblas-devel && \
    wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tar.xz && \
    tar xf Python-3.12.0.tar.xz && \
    cd Python-3.12.0 && \
    ./configure --prefix=/usr/local --enable-optimizations && \
    make -j4 && \
    make install && \
    python3.12 --version && \
    cd .. && \
    ln -sf $(which python3.12) /usr/bin/python3 && \
    dnf clean all

# Copy the requirements file
COPY requirements.txt requirements.txt

# Build Python wheels
ARG PIP_CACHE_DIR=/tmp/pip-cache
RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    pip3 wheel \
        --wheel-dir=/tmp/wheels \
        --no-binary pycurl \
        -r requirements.txt \
        py-spy

# The final stage - slim version
# ------------------------------
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.3 as slim-stage
ARG NB_USER=jovyan \
    NB_UID=1000 \
    HOME=/home/jovyan

# Install tini and required libraries
RUN microdnf install -y \
        wget \
        shadow-utils \
        libpq \
        sqlite && \
    rm -rf /var/cache/yum

RUN wget https://github.com/krallin/tini/releases/download/v0.19.0/tini-ppc64el && \
    mv tini-ppc64el /usr/bin/tini && \
    chmod +x /usr/bin/tini

# Add Python 3.12 from build-stage
COPY --from=build-stage /usr/local /usr/local
COPY --from=build-stage /usr/bin/python3 /usr/bin/python3

# Create a non-root user
RUN useradd -u ${NB_UID} -m -d ${HOME} ${NB_USER}

# Install Python packages
COPY requirements.txt /tmp/requirements.txt
ARG PIP_CACHE_DIR=/tmp/pip-cache
RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    --mount=type=cache,from=build-stage,source=/tmp/wheels,target=/tmp/wheels \
    pip3 install \
        --no-index \
        --find-links=/tmp/wheels/ \
        -r /tmp/requirements.txt
WORKDIR /srv/jupyterhub
RUN chown ${NB_USER}:${NB_USER} /srv/jupyterhub
USER ${NB_USER}
EXPOSE 8081
ENTRYPOINT ["tini", "--"]
CMD ["jupyterhub", "--config", "/usr/local/etc/jupyterhub/jupyterhub_config.py"]

# The final stage - default version
# ---------------------------------
FROM slim-stage as default-stage
USER root
ARG PIP_CACHE_DIR=/tmp/pip-cache

RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    --mount=type=cache,from=build-stage,source=/tmp/wheels,target=/tmp/wheels \
    pip3 install \
        --no-index \
        --find-links=/tmp/wheels/ \
        py-spy
RUN microdnf install -y \
        bind-utils \
        git \
        less \
        sqlite \
        sqlite-devel \
        vim && \
    rm -rf /var/cache/yum
USER ${NB_USER}
