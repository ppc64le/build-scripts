FROM registry.access.redhat.com/ubi8/ubi

ENV LATEST_STABLE_RELEASE 1.10.4

RUN yum install -y make git wget && \
        cd /tmp && \
        wget https://storage.googleapis.com/golang/go1.9.1.linux-ppc64le.tar.gz && \
        tar -C /usr/local -xzf go1.9.1.linux-ppc64le.tar.gz && \
        export PATH=$PATH:/usr/local/go/bin && \
        export GOPATH=$HOME/go && \
        go get -d github.com/influxdata/telegraf && \
        go get github.com/golang/dep  && \
        go get github.com/golang/dep/cmd/dep && \
        cd $GOPATH/src/github.com/golang/dep  && \
        go install ./... && \
        cd $GOPATH/src/github.com/influxdata/telegraf && \
        git checkout ${LATEST_STABLE_RELEASE} && \
        make && \
        rm -rf /tmp/go1.9.1.linux-ppc64le.tar.gz /usr/local/go $GOPATH/src/github.com/golang  $GOPATH/bin/ $GOPATH/pkg/ && \
        yum remove -y make git wget && \
        sed -i 's/# skip_database_creation = false/skip_database_creation = true/g' /root/go/src/github.com/influxdata/telegraf/etc/telegraf.conf

EXPOSE 8125/udp 8092/udp 8094

ENV TELEGRAF_CONFIG_PATH "/root/go/src/github.com/influxdata/telegraf/etc/telegraf.conf"
ENV PATH "$PATH:/root/go/src/github.com/influxdata/telegraf/"
COPY entrypoint.sh /entrypoint.sh

RUN groupadd telegraf && useradd -r -g telegraf telegraf -m -d /home/telegraf/

USER telegraf

ENTRYPOINT ["/entrypoint.sh"]
CMD ["telegraf"]

