# Base image: RHEL 9.6 Universal Base Image
FROM registry.access.redhat.com/ubi9/ubi:9.6

#adding vars
ENV SEARXNG_PATH=/usr/local/searxng \
    SEARXNG_USER=searxng \
    PYTHONUNBUFFERED=1 \
    LANG=en_US.UTF-8

# Adding ports and address
ENV SEARXNG_PORT=8888 \
    SEARXNG_BIND_ADDRESS=0.0.0.0

# Create path for searxng
#RUN mkdir -p /usr/local/searxng 

# Update system and install dependencies
RUN dnf -y update && \
    dnf -y install \
        git \
        python3.12 \
        python3.12-pip \
        python3.12-devel \
        gcc \
        gcc-c++ \
        make \
        nginx \
        openssl \
        which \
	wget \
        shadow-utils && \
    dnf clean all


# use python 9.12
RUN alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 10 && alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 20 && alternatives --set python3 /usr/bin/python3.12


# download and use sqlite3.51
RUN cd /tmp && \
    wget https://www.sqlite.org/2025/sqlite-autoconf-3510000.tar.gz && \
    tar xzf sqlite-autoconf-3510000.tar.gz && \
    cd sqlite-autoconf-3510000 && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && make install && \
    ln -sf /usr/local/bin/sqlite3 /usr/bin/sqlite3 && \
    ldconfig && \
    sqlite3 --version


# Create non-root user
RUN useradd -r -m -d ${SEARXNG_PATH} -s /sbin/nologin ${SEARXNG_USER}

WORKDIR ${SEARXNG_PATH}
# Clone SearXNG
RUN git clone https://github.com/searxng/searxng.git 

WORKDIR ${SEARXNG_PATH}/${SEARXNG_USER}
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Install SearXNG and ensure all Python deps (including msgspec) are installed
RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install msgspec uvloop orjson pyyaml requests uwsgi pybind11 httpx && \
    python3 -m pip install -e . --use-pep517 --no-build-isolation

# Copy the entrypoint script from your host to the container
COPY entrypoint.sh /usr/local/bin/
# Make the script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Fix permissions
RUN chown -R ${SEARXNG_USER}:${SEARXNG_USER} ${SEARXNG_PATH}
USER ${SEARXNG_USER}
EXPOSE 8888
ENTRYPOINT ["entrypoint.sh"]

# Run via webapp.py
CMD ["/bin/sh", "-c", "python3 ${SEARXNG_PATH}/${SEARXNG_USER}/searx/webapp.py"]
