FROM registry.access.redhat.com/ubi8

COPY licenses /licenses

ENV APP_ROOT /opt/app-root
ENV PATH /root/go/bin:/usr/local/go/bin:/opt/app-root/src/go/bin/:$PATH
ARG PACKAGE_VERSION=v2.5.1

RUN yum install -y sudo \
		&& yum update -y \
		&& yum install -y gcc-c++ wget git clang make pkg-config pkgconfig unzip

#install bazel
RUN dnf install -y dnf-plugins-core \	
		&& dnf copr enable vbatts/bazel -y \
		&& dnf install -y bazel4

#install go 1.19		
RUN wget https://go.dev/dl/go1.19.3.linux-ppc64le.tar.gz \
		&& rm -rf /usr/local/go \
		&& tar -C /usr/local -xzf  go1.19.3.linux-ppc64le.tar.gz 

#install rustup
RUN wget https://static.rust-lang.org/dist/rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz \
		&& tar -xzf rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz \
		&& cd rust-1.65.0-powerpc64le-unknown-linux-gnu \
		&& ./install.sh \
		&& cd ..

#install protoc
RUN git clone https://github.com/protocolbuffers/protobuf.git \
		&& cd protobuf \
		&& git checkout v21.5 \
		&& git submodule update --init --recursive \
		&& bazel build :protoc :protobuf \
		&& cp bazel-bin/protoc /usr/local/bin \
		&& cd ..

RUN cd /tmp \
		&& wget https://github.com/protocolbuffers/protobuf/releases/download/v21.9/protoc-21.9-linux-ppcle_64.zip \
		&& unzip protoc-21.9-linux-ppcle_64.zip \
		&& cd include \
		&& cp -r google /usr/local/include/ \
		&& cd / 
		
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28

RUN mkdir -p ${APP_ROOT}/src/go/src/github.com/influxdata \
        && cd ${APP_ROOT}/src/go/src/github.com/influxdata \
        && git clone https://github.com/influxdata/influxdb.git \
        && cd ${APP_ROOT}/src/go/src/github.com/influxdata/influxdb \
        && git checkout $PACKAGE_VERSION

RUN cd ${APP_ROOT}/src/go/src/github.com/influxdata/influxdb \
        && make \
        && go install ./cmd/...

EXPOSE 8086

RUN mkdir -p ${APP_ROOT}/var/lib/influxdb
VOLUME ${APP_ROOT}/var/lib/influxdb

# Copy the entrypoint scripts into the container
COPY  ./scripts/influxdb.conf  ${APP_ROOT}/etc/influxdb/influxdb.conf
COPY  ./scripts/entrypoint.sh /entrypoint.sh
COPY  ./scripts/init-influxdb.sh /init-influxdb.sh

RUN chmod a+x /entrypoint.sh /init-influxdb.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]