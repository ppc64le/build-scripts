FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v2.11.2
ARG NODE_VERSION=v20.10.0

RUN yum install -y --allowerasing yum-utils python38 python38-devel git wget gcc gcc-c++ libffi make && \
    yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/ && \
    yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/ && \
    yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/ && \
    wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official && \
    mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

RUN yum install -y git pkgconf-pkg-config librsvg2 diffutils pixman pixman-devel gcc-c++ cairo-devel pango-devel libjpeg-turbo-devel giflib-devel && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    source "$HOME"/.bashrc && \
    echo "installing nodejs $NODE_VERSION" && \
    nvm install "$NODE_VERSION" >/dev/null && \
    nvm use $NODE_VERSION

RUN git clone https://github.com/Automattic/node-canvas && \
    cd node-canvas/ && \
    git checkout $PACKAGE_VERSION && \
    source "$HOME"/.bashrc && \
    npm install

CMD ["/bin/bash"]
