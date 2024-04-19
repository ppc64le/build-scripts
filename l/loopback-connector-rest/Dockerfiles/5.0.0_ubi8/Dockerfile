FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v5.0.0

RUN yum install -y python38 python38-devel git gcc gcc-c++ libffi make

# Install nvm and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash \
    && source ~/.bashrc \
    && nvm install v18.9.0 \
    && nvm use v18.9.0

RUN git clone https://github.com/loopbackio/loopback-connector-rest \
    && cd loopback-connector-rest/ \
    && git checkout $PACKAGE_VERSION \
    && source ~/.bashrc \
    && npm install

CMD ["/bin/bash"]

