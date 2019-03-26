## -*- docker-image-name: "docker-crate" -*-
#
# Crate Dockerfile
# https://github.com/crate/docker-crate
#

FROM centos:7

RUN groupadd crate && useradd -u 1000 -g crate -d /crate crate

ENV CRATE_VERSION 3.2.5
ENV CRASH_VERSION 0.24.2

# install crate
RUN yum install -y yum-utils \ #https://centos7.iuscommunity.org/ius-release.rpm \
    && yum makecache \
    && yum install -y python36u openssl java-1.8.0-openjdk unzip java-devel \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && curl -fSL -O https://cdn.crate.io/downloads/releases/crate-$CRATE_VERSION.tar.gz \
    && curl -fSL -O https://cdn.crate.io/downloads/releases/crate-$CRATE_VERSION.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 90C23FC6585BC0717F8FBFC37FAAE51A06F6EAEB \
    && gpg --batch --verify crate-$CRATE_VERSION.tar.gz.asc crate-$CRATE_VERSION.tar.gz \
    && rm -rf "$GNUPGHOME" crate-$CRATE_VERSION.tar.gz.asc \
    && tar -xf crate-$CRATE_VERSION.tar.gz -C /crate --strip-components=1 \
    #&& rm crate-$CRATE_VERSION.tar.gz \
    #&& ln -sf /usr/bin/python3.6 /usr/bin/python3 \
    #&& ln -sf /usr/bin/python3.6 /usr/bin/python
    && cd /crate/lib && mv /crate/lib/crate-app-$CRATE_VERSION.jar /crate/lib/crate-app-$CRATE_VERSION.zip \
        && mkdir test && cd test && mv /crate/lib/crate-app-$CRATE_VERSION.zip . \
        && unzip -n crate-app-$CRATE_VERSION.zip && rm -rf crate-app-$CRATE_VERSION.zip \
        && mkdir /es

ADD elasticsearch-6.5.1-SNAPSHOT.zip /es/
RUN cd /es && unzip elasticsearch-6.5.1-SNAPSHOT.zip \
        && cp -rf org/elasticsearch/bootstrap/* /crate/lib/test/org/elasticsearch/bootstrap/ \
        && cd /crate/lib/test && jar cf crate-app-$CRATE_VERSION.jar . \
        && mv crate-app-$CRATE_VERSION.jar /crate/lib/ \
        && cd /crate/lib/ && rm -rf test/ crate-app-$CRATE_VERSION.zip \
    && cd / && rm crate-$CRATE_VERSION.tar.gz \
    && yum remove -y unzip java-devel \
    && ln -sf /usr/bin/python3.6 /usr/bin/python3 \
    && ln -sf /usr/bin/python3.6 /usr/bin/python

ADD config/crate.yml /crate/config/crate.yml
ADD config/log4j2.properties /crate/config/log4j2.properties

# install crash
RUN curl -fSL -O https://cdn.crate.io/downloads/releases/crash_standalone_$CRASH_VERSION \
    && curl -fSL -O https://cdn.crate.io/downloads/releases/crash_standalone_$CRASH_VERSION.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 90C23FC6585BC0717F8FBFC37FAAE51A06F6EAEB \
    && gpg --batch --verify crash_standalone_$CRASH_VERSION.asc crash_standalone_$CRASH_VERSION \
    && rm -rf "$GNUPGHOME" crash_standalone_$CRASH_VERSION.asc \
    && mv crash_standalone_$CRASH_VERSION /usr/local/bin/crash \
    && chmod +x /usr/local/bin/crash

ENV PATH /crate/bin:$PATH
# Default heap size for Docker, can be overwritten by args
ENV CRATE_HEAP_SIZE 512M

RUN mkdir -p /data/data /data/log

VOLUME /data

WORKDIR /data

# http: 4200 tcp
# transport: 4300 tcp
# postgres protocol ports: 5432 tcp
EXPOSE 4200 4300 5432

# These COPY commands have been moved before the last one due to the following issues:
# https://github.com/moby/moby/issues/37965#issuecomment-448926448
# https://github.com/moby/moby/issues/38866
ADD config/crate.yml /crate/config/crate.yml
ADD config/log4j2.properties /crate/config/log4j2.properties

LABEL maintainer="Crate.io <office@crate.io>" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="{{ BUILD_TIMESTAMP }}" \
    org.label-schema.name="crate" \
    org.label-schema.description="CrateDB is a distributed SQL database handles massive amounts of machine data in real-time." \
    org.label-schema.url="https://crate.io/products/cratedb/" \
    org.label-schema.vcs-url="https://github.com/crate/docker-crate" \
    org.label-schema.vendor="Crate.io" \
    org.label-schema.version="{{ CRATE_VERSION }}"

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crate"]
