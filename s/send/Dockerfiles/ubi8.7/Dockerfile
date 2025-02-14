FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

ARG PACKAGE_VERSION=0.18.0

RUN yum install -y git

RUN  export NODE_VERSION=${NODE_VERSION:-16} && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    source "$HOME"/.bashrc && \
    echo "installing nodejs $NODE_VERSION" && \
    nvm install "$NODE_VERSION" >/dev/null && \
    nvm use $NODE_VERSION && \
    git clone https://github.com/pillarjs/send && \
	cd send && \
    git checkout $PACKAGE_VERSION && \
	npm install

CMD ["/bin/bash"]