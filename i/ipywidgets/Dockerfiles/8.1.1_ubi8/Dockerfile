FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=8.1.1
ARG NODE_VERSION=v16.20.2

RUN yum install -y python38 python38-devel git gcc gcc-c++ libffi make && \
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
