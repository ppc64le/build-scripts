FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v2.18.0

RUN yum install -y gcc gcc-c++ git wget make python39 python39-devel python39-pip && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash && \
    source ~/.bashrc && \
    nvm install 18

RUN git clone https://github.com/nodejs/nan && \
    cd nan && \
    git checkout $PACKAGE_VERSION && \
    source ~/.bashrc && \
    npm install
    
CMD ["/bin/bash"]
