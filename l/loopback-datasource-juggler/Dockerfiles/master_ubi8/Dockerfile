FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG NODE_VERSION=v18.19.0

RUN yum install -y git make wget gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless sudo librsvg2 libjpeg-turbo libjpeg-turbo-devel giflib && \
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk && \
    export PATH=$PATH:$JAVA_HOME/bin

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    source "$HOME"/.bashrc && \
    echo "installing nodejs $NODE_VERSION" && \
    nvm install "$NODE_VERSION" >/dev/null && \
    nvm use $NODE_VERSION

RUN git clone https://github.com/loopbackio/loopback-datasource-juggler && \
    cd loopback-datasource-juggler/ && \
    source "$HOME"/.bashrc && \
    npm ci --ignore-scripts && \
    npm run build

CMD ["/bin/bash"]
