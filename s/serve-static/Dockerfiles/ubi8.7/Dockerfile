FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

ARG PACKAGE_VERSION=v1.15.0

RUN yum update -y && \
        yum install -y git && \
        export NODE_VERSION=${NODE_VERSION:-16} && \
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
        source "$HOME"/.bashrc && \
        echo "installing nodejs $NODE_VERSION" && \
        nvm install "$NODE_VERSION" >/dev/null && \
        nvm use $NODE_VERSION && \
        git clone https://github.com/expressjs/serve-static && \
        cd serve-static && \
        git checkout $PACKAGE_VERSION && \
        npm install && npm fund

CMD ["/bin/bash"]

