FROM registry.access.redhat.com/ubi9/ubi:9.3 as builder

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v2.4.4
ARG NODE_VERSION=v16.20.2

RUN yum install -y patch bzip2 git make gcc-c++ openssl-devel libcurl-devel wget m4 ncurses-devel libicu-devel python3 python3-devel protobuf-c && \
    yum install -y https://dl.fedoraproject.org/pub/epel/9/Everything/ppc64le/Packages/e/epel-release-9-7.el9.noarch.rpm && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    source "$HOME"/.bashrc && \
    echo "installing nodejs $NODE_VERSION" && \
    nvm install "$NODE_VERSION" >/dev/null && \
    nvm use $NODE_VERSION

RUN ln -s /usr/bin/python3 /usr/bin/python && \
    git clone https://github.com/rethinkdb/rethinkdb.git && \
    cd rethinkdb && \
    git checkout $PACKAGE_VERSION && \
    ./configure --allow-fetch && \
    make -j4 && \
    make install

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

COPY --from=builder /rethinkdb/build/release/rethinkdb /usr/bin

VOLUME ["/data"]

WORKDIR /data

CMD ["rethinkdb", "--bind", "all"]

#   process cluster webui
EXPOSE 28015 29015 8080
