FROM registry.access.redhat.com/ubi9/ubi:9.3
 
MAINTAINER "Vinod K <Vinod.K1@ibm.com>"
 
ARG PACKAGE_VERSION=master
 
RUN yum install -y git wget gcc gcc-c++
 
RUN export NODE_VERSION=${NODE_VERSION:-18} && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    source "$HOME"/.bashrc && \
    echo "installing nodejs $NODE_VERSION" && \
    nvm install "$NODE_VERSION" >/dev/null && \
    nvm use $NODE_VERSION
 
RUN git clone https://github.com/ilikenwf/nestedSortable && \
    cd nestedSortable && \
    git checkout $PACKAGE_VERSION && \
    source "$HOME"/.bashrc && \
    npm install 
 
CMD ["/bin/bash"]
