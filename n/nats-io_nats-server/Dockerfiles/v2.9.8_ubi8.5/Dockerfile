FROM registry.access.redhat.com/ubi8

ARG PACKAGE_VERSION=v2.9.8
ENV PATH /usr/local/go/bin:$PATH

RUN yum -y update \
		&& yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq wget gcc-c++
	
RUN wget https://go.dev/dl/go1.19.3.linux-ppc64le.tar.gz \
		&& rm -rf /usr/local/go \
		&& tar -C /usr/local -xzf  go1.19.3.linux-ppc64le.tar.gz 

RUN mkdir -p src/github.com/nats-io \
		&& cd src/github.com/nats-io/ \
		&& git clone https://github.com/nats-io/natscli.git \
		&& cd natscli/nats \
		&& go build -ldflags "-w -X main.version=${PACKAGE_VERSION}" -o /nats

RUN go install github.com/nats-io/nsc@latest

RUN cd / \
		&& mkdir -p nats-server \
		&& mkdir -p /nats-server/conf \
		&& cp /nats /bin/nats \
		&& cp /root/go/bin/nsc /bin/nsc

COPY nats-server.conf /nats-server/conf/nats-server.conf

EXPOSE 4222 8222 6222 5222

CMD ["-c", "/nats-server/conf/nats-server.conf"]
