FROM registry.access.redhat.com/ubi8/ubi:latest

# For deployment, we need
# libc6 - dynamically linked by cockroach binary
# ca-certificates - to authenticate TLS connections for telemetry and
#                   bulk-io with S3/GCS/Azure
# tzdata - for time zone functions
RUN yum install -y glibc.ppc64le ca-certificates.noarch ncurses.ppc64le tzdata.noarch

RUN mkdir -p /cockroach
COPY cockroach.sh /cockroach/
COPY cockroachoss /cockroach/cockroach
# Set working directory so that relative paths
# are resolved appropriately when passed as args.
WORKDIR /cockroach/

# Include the directory into the path
# to make it easier to invoke commands
# via Docker
ENV PATH=/cockroach:$PATH

ENV COCKROACH_CHANNEL=ibmcom-docker

EXPOSE 26257 8080
ENTRYPOINT ["/cockroach/cockroach.sh"]

