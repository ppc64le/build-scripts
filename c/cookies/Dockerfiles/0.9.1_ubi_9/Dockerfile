FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Mohit Pawar <mohit.pawar@ibm.com>

ARG PACKAGE_VERSION=0.9.1

RUN yum update -y && \
    export NODE_VERSION=${NODE_VERSION:-16} && \
    yum install git make -y && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    source "$HOME"/.bashrc && \
    echo "installing nodejs $NODE_VERSION" && \
    nvm install "$NODE_VERSION" >/dev/null && \
    nvm use $NODE_VERSION && \
    git clone http://github.com/pillarjs/cookies && \
    cd cookies/ && \
    git checkout $PACKAGE_VERSION && \
    npm install 

CMD ["/bin/bash"]
