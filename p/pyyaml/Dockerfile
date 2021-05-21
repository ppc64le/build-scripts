FROM ubuntu:focal
MAINTAINER "Eshant Gupta <guptaeshant@gmail.com>"
ENV TOXENV=py38
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /root
RUN \
    apt-get update && apt-get upgrade -y && \
    apt-get install -yqq --no-install-suggests \
            build-essential libtool pkg-config \
            autoconf python3-pip python3-dev git && \
    apt-get clean && \
    python3 -m pip install --upgrade pip setuptools wheel --no-cache-dir && \
    python3 -m pip install cython tox --no-cache-dir && \
   git clone https://github.com/ezeeyahoo/pyyaml.git pyyaml && \
   git clone https://github.com/yaml/libyaml.git /tmp/libyaml && \
   cd /tmp/libyaml && \
	git reset --hard 0.2.2 && \
	./bootstrap && \
	./configure && \
	make && \
	make test-all && \
	ldconfig && \
	cd && \
	cd pyyaml && \
        tox
