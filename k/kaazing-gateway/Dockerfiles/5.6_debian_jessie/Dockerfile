#Adapted from the original Dockerfile @https://github.com/kaazing/gateway.docker/blob/a40c8da9d2c2925bdd78b9a6d1b6da3fe89322d1/Dockerfile
FROM ppc64le/openjdk:8-jre

MAINTAINER Snehlata Mohite (smohite@us.ibm.com)

ENV KAAZING_GATEWAY_VERSION 5.6.0
ENV KAAZING_GATEWAY_URL https://oss.sonatype.org/content/repositories/releases/org/kaazing/gateway.distribution/${KAAZING_GATEWAY_VERSION}/gateway.distribution-${KAAZING_GATEWAY_VERSION}.tar.gz

# Set Working Dir
WORKDIR /kaazing-gateway

# Get the latest stable version of gateway

RUN curl -fSL -o gateway.tar.gz $KAAZING_GATEWAY_URL \
        && curl -fSL -o gateway.tar.gz.asc ${KAAZING_GATEWAY_URL}.asc \
        && tar -xvf gateway.tar.gz --strip-components=1 \
        && rm gateway.tar.gz*

# By default, Java uses /dev/random to gather entropy data for cryptographic
# needs. However, using /dev/random can cause delays during Gateway startup,
# especially in virtualized environments. /dev/urandom does not require
# collection of entropy data in subsequent runs.
# See: https://github.com/kaazing/gateway/issues/167
ENV GATEWAY_OPTS="-Xmx512m -Djava.security.egd=file:/dev/urandom"

# add new files to the path
ENV PATH=$PATH:/kaazing-gateway/bin

# Expose Ports
EXPOSE 8000

# Define default command
CMD ["gateway.start"]

