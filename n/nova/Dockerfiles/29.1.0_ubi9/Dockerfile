FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vipul Ajmera <Vipul.Ajmera@ibm.com>"

ARG PACKAGE_VERSION=29.1.0

RUN yum install -y git wget python3 python3-devel python3-pip gcc gcc-c++ make && \
    yum install -y openssl-devel bzip2-devel libffi-devel zlib-devel libxml2-devel libxslt-devel procps-ng

RUN wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz && \
    tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz && \
    cd rust-1.75.0-powerpc64le-unknown-linux-gnu && \
    ./install.sh && \
    export PATH=$HOME/.cargo/bin:$PATH

RUN git clone https://github.com/openstack/nova && \
    cd nova && \
    git checkout $PACKAGE_VERSION

RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    python3 -m pip install --upgrade pip setuptools && \
    python3 -m pip install tox wheel && \
    python3 -m pip install -r nova/requirements.txt && \
    python3 -m pip install -r nova/test-requirements.txt && \
    cd nova && \
    python3 setup.py install

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

CMD ["/bin/bash"]
