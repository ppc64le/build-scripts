FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v5.3.3

RUN yum install -y git wget gcc gcc-c++

RUN export NODE_VERSION=${NODE_VERSION:-18} && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    source "$HOME"/.bashrc && \
    echo "installing nodejs $NODE_VERSION" && \
    nvm install "$NODE_VERSION" >/dev/null && \
    nvm use $NODE_VERSION

RUN git clone https://github.com/twbs/bootstrap && \
    cd bootstrap && \
    git checkout $PACKAGE_VERSION && \
    source "$HOME"/.bashrc && \
    npm install npm-run-all eslint lockfile-lint stylelint css-lint lint find-unused-sass-variables rollup stylelint-config-twbs-bootstrap -g && \
    npm install -g

CMD ["/bin/bash"]
