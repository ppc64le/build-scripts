FROM registry.access.redhat.com/ubi9/ubi as builder

ARG GO_VERSION=1.22.1
ARG PACKAGE_VERSION=v8.13.2

RUN yum install -y wget gcc-c++ make git && \
    export GOROOT=${GOROOT:-"/usr/local/go"} && \
    export GOPATH=${GOPATH:-$HOME/go} && \
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin && \
    wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    git clone https://github.com/elastic/beats && \
    cd beats && git checkout $PACKAGE_VERSION && \
    cd filebeat && \
    make

FROM registry.access.redhat.com/ubi9/ubi

RUN yum -y --setopt=tsflags=nodocs update && \
     yum clean all

 ENV ELASTIC_CONTAINER "true"
 ENV PATH=/usr/share/filebeat:$PATH

 COPY --from=builder /beats/filebeat/filebeat /usr/share/filebeat/
 COPY --from=builder /beats/filebeat/filebeat.yml /usr/share/filebeat/
 COPY --from=builder /beats/filebeat/modules.d /usr/share/filebeat/modules.d
 COPY --from=builder /beats/filebeat/module /usr/share/filebeat/module

 COPY docker-entrypoint /usr/local/bin/docker-entrypoint
 RUN chmod 755 /usr/local/bin/docker-entrypoint

 RUN groupadd --gid 1000 filebeat

 RUN mkdir  /usr/share/filebeat/data /usr/share/filebeat/logs && \
     chown -R root:root /usr/share/filebeat && \
     find /usr/share/filebeat -type d -exec chmod 0750 {} \; && \
     find /usr/share/filebeat -type f -exec chmod 0640 {} \; && \
     chmod 0750 /usr/share/filebeat/filebeat && \
     chmod 0770 /usr/share/filebeat/modules.d && \
     chmod 0770 /usr/share/filebeat/data /usr/share/filebeat/logs

 RUN useradd -M --uid 1000 --gid 1000 --groups 0 --home /usr/share/filebeat filebeat

 USER filebeat

 EXPOSE 5044

 WORKDIR /usr/share/filebeat
 ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
 CMD ["-environment", "container"]
