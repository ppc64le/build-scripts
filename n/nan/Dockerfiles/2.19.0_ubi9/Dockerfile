FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v2.19.0
ARG NODE_VERSION=${NODE_VERSION:-18}
RUN yum install -y python3 python3-devel.ppc64le git gcc gcc-c++ libffi make && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    source "$HOME"/.bashrc && \
    echo "installing nodejs $NODE_VERSION" && \
    nvm install "$NODE_VERSION" >/dev/null && \
    nvm use $NODE_VERSION

RUN git clone https://github.com/nodejs/nan && \
    cd nan && \
    git checkout $PACKAGE_VERSION && \
    source "$HOME"/.bashrc && \
    npm install

CMD ["/bin/bash"]

