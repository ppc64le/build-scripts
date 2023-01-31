FROM registry.access.redhat.com/ubi8/ubi:8.5

ARG PACKAGE_VERSION=v1.62.0

RUN yum install -y gcc-c++ make python36 wget git tar zip npm && \
    npm install -g yarn

RUN wget https://go.dev/dl/go1.18.7.linux-ppc64le.tar.gz && \
        tar -C /usr/local -xzf go1.18.7.linux-ppc64le.tar.gz && \
        curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash


RUN git clone https://github.com/kiali/kiali.git && \
        cd kiali/ && \
        git checkout $PACKAGE_VERSION && \
        export GOROOT=/usr/local/go/ && \
        export GOPATH=$HOME && \
        export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
        make lint-install && \
        make -e GO_BUILD_FLAGS=-race -e CGO_ENABLED=1 clean-all build && \
        export NVM_DIR="$HOME/.nvm" && \
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && \
        nvm install 14 && \
        nvm use 14 && \
        make clean-all build-ui

CMD ["/bin/bash"]

