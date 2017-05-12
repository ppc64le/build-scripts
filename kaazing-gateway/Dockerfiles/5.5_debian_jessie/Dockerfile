FROM ppc64le/openjdk:8-jre

MAINTAINER Snehlata Mohite (smohite@us.ibm.com)

# pub   2048R/385B4D59 2015-07-01 [expires: 2017-12-08]
#       Key fingerprint = F8F4 B66E 022A 4668 E532  DAC0 3AA0 B82C 385B 4D59
# sub   2048R/26C0219B 2015-07-01 [expires: 2017-12-08]

ENV KAAZING_GATEWAY_VERSION 5.5.0
ENV KAAZING_GATEWAY_URL https://oss.sonatype.org/content/repositories/releases/org/kaazing/gateway.distribution/${KAAZING_GATEWAY_VERSION}/gateway.distribution-${KAAZING_GATEWAY_VERSION}.tar.gz

# Set Working Dir
WORKDIR /kaazing-gateway

# Get the latest stable version of gateway

RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys F8F4B66E022A4668E532DAC03AA0B82C385B4D59\
        && curl -fSL -o gateway.tar.gz $KAAZING_GATEWAY_URL \
        && curl -fSL -o gateway.tar.gz.asc ${KAAZING_GATEWAY_URL}.asc \
        && gpg --verify gateway.tar.gz.asc \
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
