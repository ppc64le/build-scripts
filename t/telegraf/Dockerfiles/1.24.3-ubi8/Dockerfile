FROM registry.access.redhat.com/ubi8/ubi:8.7 as builder

ARG GO_VERSION=1.19

ARG PACKAGE_VERSION=v1.24.3

RUN yum -y update && \
        yum install -y make git wget gcc-c++ && \
            wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
                tar -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
                export GOPATH=$PWD/go && \
                export PATH=$PATH:$GOPATH/bin && \
                echo $GOPATH && mkdir -p $GOPATH/src/github.com/influxdata && \
                cd $GOPATH/src/github.com/influxdata && \
                git clone  https://github.com/influxdata/telegraf.git && \
                cd telegraf && git checkout $PACKAGE_VERSION && \
                make

EXPOSE 8125/udp 8092/udp 8094

ENV TELEGRAF_CONFIG_PATH "/root/go/src/github.com/influxdata/telegraf/etc/telegraf.conf"
ENV PATH "$PATH:/root/go/src/github.com/influxdata/telegraf/"
COPY entrypoint.sh /entrypoint.sh

RUN groupadd telegraf && useradd -r -g telegraf telegraf -m -d /home/telegraf/

USER telegraf

ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]
