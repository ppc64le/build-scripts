FROM registry.access.redhat.com/ubi9/ubi:9.3

ARG PACKAGE_VERSION=v1.85.0

RUN yum install python3 python3-devel python3-pip wget git tar zip  make gcc-c++ -y

RUN git clone https://github.com/kiali/kiali.git && \
    cd kiali/ && \
    git checkout $PACKAGE_VERSION && \
    wget https://go.dev/dl/go1.22.1.linux-ppc64le.tar.gz && \
    tar -C  /usr/local -xf go1.22.1.linux-ppc64le.tar.gz && \
    export GOROOT=/usr/local/go && \
    export GOPATH=$HOME && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
    NODE_VERSION=20 && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash && \
    source ~/.bashrc && \
    nvm install $NODE_VERSION && \
    npm install -g yarn && \
    make lint-install && \
    make -e GO_BUILD_FLAGS=-race -e CGO_ENABLED=1 clean-all build && \
    make clean-all build-ui

CMD ["/bin/bash"]
