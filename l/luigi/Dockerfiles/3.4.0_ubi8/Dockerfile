FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=3.4.0

RUN yum install -y git python39 python39-devel python39-pip  gcc-c++ gcc wget bzip2 bzip2-devel openssl openssl-devel make && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    PATH="$HOME/.cargo/bin:$PATH" && \
    source $HOME/.cargo/env && \
    rustc --version


RUN git clone https://github.com/spotify/luigi.git && \
    cd luigi/ && \
    git checkout $PACKAGE_VERSION && \
    pip3 install deps


CMD ["/bin/bash"]
