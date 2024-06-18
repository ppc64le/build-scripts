FROM registry.access.redhat.com/ubi9

RUN yum install -y gcc gcc-c++ python3 python3-devel git wget sudo make autoconf automake zlib-devel bzip2 bzip2-devel xz-devel curl-devel openssl-devel ncurses-devel diffutils libtool json-c.ppc64le elfutils-libelf.ppc64le cmake patch libcap

ARG PACKAGE_VERSION=v2.7.6

COPY licenses /licenses

#install protbuf
RUN git clone https://github.com/protocolbuffers/protobuf && \
    cd protobuf && \
    git checkout v3.17.3 && \
    ./autogen.sh && ./configure && \
    make && make install && cd ..

#install protoc-c
RUN export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig && \
    git clone https://github.com/protobuf-c/protobuf-c && \
    cd protobuf-c && \
    git checkout v1.4.0 && \
    ./autogen.sh && ./configure && \
    make && make install && cd ..

#install rustc
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    PATH="$HOME/.cargo/bin:$PATH" && \
    source $HOME/.cargo/env && \
    rustc --version

RUN GO_VERSION=1.21.6 && \
    wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
    rm -rf go$GO_VERSION.linux-ppc64le.tar.gz && \
    export GOROOT=/usr/local/go && \
    export GOPATH=$HOME && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

RUN git clone https://github.com/influxdata/influxdb && \
    cd influxdb && \
    git checkout $PACKAGE_VERSION && \
    export GOROOT=/usr/local/go && \
    export GOPATH=$HOME && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
    PATH="$HOME/.cargo/bin:$PATH" && \
    source $HOME/.cargo/env && \
    make && \
    go install ./...

EXPOSE 8086

# Copy the entrypoint scripts into the container
COPY ./scripts/influxdb.conf  /influxdb.conf
COPY ./scripts/entrypoint.sh /entrypoint.sh
COPY ./scripts/init-influxdb.sh /init-influxdb.sh

RUN chmod a+x /entrypoint.sh /init-influxdb.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]