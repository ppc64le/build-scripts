FROM golang:1.11 as builder

WORKDIR /go/src/github.com/influxdata/influxdb

RUN go get -u github.com/golang/dep/... && \
        git clone https://github.com/influxdata/influxdb.git . && \
        git checkout 1.8 && \
        dep ensure -vendor-only && \
        go install ./cmd/...

FROM registry.access.redhat.com/ubi7/ubi:latest
COPY --from=builder /go/bin/* /usr/bin/
COPY --from=builder /go/src/github.com/influxdata/influxdb/etc/config.sample.toml /etc/influxdb/influxdb.conf

EXPOSE 8086
VOLUME /var/lib/influxdb

# Copy the entrypoint scripts into the container
COPY ./scripts/entrypoint.sh /entrypoint.sh
COPY ./scripts/init-influxdb.sh /init-influxdb.sh

RUN chmod a+x /entrypoint.sh /init-influxdb.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
