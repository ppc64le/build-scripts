FROM registry.access.redhat.com/ubi8/go-toolset

# Required Labels
LABEL name="influxdb" \
        maintainer="redmark@us.ibm.com" \
        vendor="Influx Data" \
        version="1.8.0" \
        release="1" \
        summary="Red Hat UBI Influxdb" \
        description="Red Hat UBI Influxdb"

COPY licenses /licenses

# Using the "default" non-root user
USER default

ENV APP_ROOT /opt/app-root
ENV PATH /opt/app-root/src/go/bin/:$PATH

# Influxdb requires "dep" to get its dependencies
RUN go get -u github.com/golang/dep/...

RUN mkdir -p ${APP_ROOT}/src/go/src/github.com/influxdata \
        && cd ${APP_ROOT}/src/go/src/github.com/influxdata \
        && git clone https://github.com/influxdata/influxdb.git \
        && cd ${APP_ROOT}/src/go/src/github.com/influxdata/influxdb \
        && git checkout 1.8

RUN cd ${APP_ROOT}/src/go/src/github.com/influxdata/influxdb \
        && dep ensure -vendor-only \
        && go install ./cmd/...

EXPOSE 8086

RUN mkdir -p ${APP_ROOT}/var/lib/influxdb
VOLUME ${APP_ROOT}/var/lib/influxdb

# Copy the entrypoint scripts into the container
COPY --chown=default:root ./scripts/influxdb.conf  ${APP_ROOT}/etc/influxdb/influxdb.conf
COPY --chown=default:root ./scripts/entrypoint.sh /entrypoint.sh
COPY --chown=default:root ./scripts/init-influxdb.sh /init-influxdb.sh

RUN chmod a+x /entrypoint.sh /init-influxdb.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
