FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Aastha Sharma <aastha.sharma4@ibm.com>"

ARG PACKAGE_VERSION=8.1.2
ARG NODE_VERSION=v16.20.2

RUN yum install -y  wget gcc gcc-c++ python3 python3-devel.ppc64le git gcc gcc-c++ libffi make && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    source "$HOME"/.bashrc && \
    echo "installing nodejs $NODE_VERSION" && \
    nvm install "$NODE_VERSION" >/dev/null && \
    nvm use $NODE_VERSION

RUN git clone https://github.com/jupyter-widgets/ipywidgets && \
    cd ipywidgets/ && \
    git checkout $PACKAGE_VERSION && \
    python3 -m pip install --upgrade pip

CMD ["/bin/bash"]
