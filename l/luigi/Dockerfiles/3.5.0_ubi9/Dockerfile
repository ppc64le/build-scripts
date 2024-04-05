FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=3.5.0

RUN yum install -y git python3.11 python3.11-devel  python3.11-pip gcc-c++ gcc wget bzip2 bzip2-devel openssl openssl-devel make && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    PATH="$HOME/.cargo/bin:$PATH" && \
    source $HOME/.cargo/env && \
    rustc --version

RUN git clone https://github.com/spotify/luigi.git && \
    cd luigi/ && \
    git checkout $PACKAGE_VERSION && \
    pip3.11 install deps

CMD ["/bin/bash"]
