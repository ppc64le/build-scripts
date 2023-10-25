FROM registry.access.redhat.com/ubi8/ubi as builder

ARG GO_VERSION=1.18
ARG PACKAGE_VERSION=v8.5.0

RUN yum install -y wget gcc-c++ make git && \
    wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    export GOPATH=$PWD/go && \
    export PATH=$PATH:$GOPATH/bin && \
    export CGO_ENABLED="0" && \
    echo $GOPATH && mkdir -p $GOPATH/src/github.com/elastic && \
    cd $GOPATH/src/github.com/elastic && \
    git clone https://github.com/elastic/beats && \
    cd beats && git checkout $PACKAGE_VERSION && \
    cd filebeat && \
    make

FROM registry.access.redhat.com/ubi8/ubi

RUN yum -y --setopt=tsflags=nodocs update && \
     yum clean all

 LABEL org.label-schema.build-date="2020-09-01T19:58:34Z" \
         org.label-schema.schema-version="1.0" \
         org.label-schema.vendor="Elastic" \
         org.label-schema.license="Elastic License" \
         org.label-schema.name="filebeat" \
         org.label-schema.version="8.5.0" \
         org.label-schema.url="https://www.elastic.co/products/beats/filebeat" \
         org.label-schema.vcs-url="github.com/elastic/beats/v7" \
         org.label-schema.vcs-ref="ad823eca4cc74439d1a44351c596c12ab51054f5" \
         license="Elastic License description=Filebeat sends log files to Logstash or directly to Elasticsearch."

 ENV ELASTIC_CONTAINER "true"
 ENV PATH=/usr/share/filebeat:$PATH

 COPY --from=builder /go/src/github.com/elastic/beats/filebeat/filebeat /usr/share/filebeat/
 COPY --from=builder /go/src/github.com/elastic/beats/filebeat/filebeat.yml /usr/share/filebeat/
 COPY --from=builder /go/src/github.com/elastic/beats/filebeat/modules.d /usr/share/filebeat/modules.d
 COPY --from=builder /go/src/github.com/elastic/beats/filebeat/module /usr/share/filebeat/module
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
