# NOTE: This is based on the original work at https://github.com/elastic/dockerfiles/

################################################################################i
# This Dockerfile was generated from the template at https://github.com/elastic/dockerfiles/blob/v7.8.0/elasticsearch/Dockerfile
#
# Beginning of multi stage Dockerfile
################################################################################

################################################################################
# Build stage 0 `builder`:
# Extract elasticsearch artifact
# Set gid=0 and make group perms==owner perms
################################################################################

ARG PACKAGE_VERSION=v7.8.0

FROM centos:7 AS builder

MAINTAINER "Shivani Junawane <shivanij@us.ibm.com>"

ARG PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/elasticsearch/elasticsearch_7.8.0.patch

# `tini` is a tiny but valid init for containers. This is used to cleanly
# control how ES and any child processes are shut down.
#
# The tini GitHub page gives instructions for verifying the binary using
# gpg, but the keyservers are slow to return the key and this can fail the
# build. Instead, we check the binary against the published checksum.
RUN set -eux ; \
    \
    tini_bin="" ; \
    case "$(arch)" in \
        aarch64) tini_bin='tini-arm64' ;; \
        x86_64)  tini_bin='tini-amd64' ;; \
	ppc64le) tini_bin='tini-ppc64le' ;; \
        *) echo >&2 ; echo >&2 "Unsupported architecture $(arch)" ; echo >&2 ; exit 1 ;; \
    esac ; \
    curl --retry 8 -S -L -O https://github.com/krallin/tini/releases/download/v0.19.0/${tini_bin} ; \
    curl --retry 8 -S -L -O https://github.com/krallin/tini/releases/download/v0.19.0/${tini_bin}.sha256sum ; \
    sha256sum -c ${tini_bin}.sha256sum ; \
    rm ${tini_bin}.sha256sum ; \
    mv ${tini_bin} /tini ; \
    chmod +x /tini
ARG PACKAGE_VERSION
ENV PATH /usr/share/elasticsearch/bin:$PATH

RUN groupadd -g 1000 elasticsearch && \
    adduser -u 1000 -g 1000 -d /usr/share/elasticsearch elasticsearch

WORKDIR /usr/share/elasticsearch

#RUN curl --retry 8 -S -L --output /opt/elasticsearch.tar.gz     https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.8.0-linux-$(arch).tar.gz
#RUN tar zxf /opt/elasticsearch.tar.gz --strip-components=1

# Install Pre-Requisites
RUN yum install -y wget git && \
	wget https://github.com/AdoptOpenJDK/openjdk13-binaries/releases/download/jdk13u-2020-02-24-07-25/OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz && \
	tar -C /usr/local -xzf OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz && \
	export JAVA_HOME=/usr/local/jdk-13.0.2+8/ && \
	export JAVA13_HOME=/usr/local/jdk-13.0.2+8/ && \
	export PATH=$PATH:/usr/local/jdk-13.0.2+8/bin && \
	ln -sf /usr/local/jdk-13.0.2+8/bin/java /usr/bin/ &&\
	git clone https://github.com/elastic/elasticsearch.git && \
	cd elasticsearch && git checkout $PACKAGE_VERSION && \
	wget $PATCH && \
	git apply elasticsearch_7.8.0.patch && \
	mkdir -p distribution/archives/linux-ppc64le-tar && \
	echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/linux-ppc64le-tar/build.gradle && \
	mkdir -p distribution/archives/oss-linux-ppc64le-tar && \
	echo "// This file is intentionally blank. All configuration of the distribution is done in the parent project." > distribution/archives/oss-linux-ppc64le-tar/build.gradle && \
	./gradlew :distribution:archives:linux-ppc64le-tar:assemble --parallel
	
# Configurations
RUN mv elasticsearch/distribution/archives/linux-ppc64le-tar/build/distributions/elasticsearch-*-SNAPSHOT-linux-ppc64le.tar.gz /usr/share/elasticsearch && \
	cd /usr/share/elasticsearch && rm -rf elasticsearch && \
	tar -xvzf elasticsearch-*-SNAPSHOT-linux-ppc64le.tar.gz --strip-components=1 && \
	rm -rf elasticsearch-*-SNAPSHOT-linux-ppc64le.tar.gz

# JNA fix
RUN wget https://repo1.maven.org/maven2/net/java/dev/jna/jna/4.5.1/jna-4.5.1.jar && \
	mv jna-4.5.1.jar /usr/share/elasticsearch/lib/

RUN sed -i -e 's/ES_DISTRIBUTION_TYPE=tar/ES_DISTRIBUTION_TYPE=docker/' /usr/share/elasticsearch/bin/elasticsearch-env
RUN mkdir -p config config/jvm.options.d data logs
RUN chmod 0775 config config/jvm.options.d data logs
COPY config/elasticsearch.yml config/log4j2.properties config/
RUN chmod 0660 config/elasticsearch.yml config/log4j2.properties



################################################################################
# Build stage 1 (the actual elasticsearch image):
# Copy elasticsearch from stage 0
# Add entrypoint
################################################################################

FROM centos:7

MAINTAINER "Shivani Junawane <shivanij@us.ibm.com>"

ENV ELASTIC_CONTAINER true

ARG PACKAGE_VERSION

COPY --from=builder /tini /tini

RUN for iter in {1..10}; do yum update --setopt=tsflags=nodocs -y && \
    yum install --setopt=tsflags=nodocs -y nc shadow-utils zip unzip && \
    yum clean all && exit_code=0 && break || exit_code=$? && echo "yum error: retry $iter in 10s" && sleep 10; done; \
    (exit $exit_code)

RUN groupadd -g 1000 elasticsearch && \
    adduser -u 1000 -g 1000 -G 0 -d /usr/share/elasticsearch elasticsearch && \
    chmod 0775 /usr/share/elasticsearch && \
    chgrp 0 /usr/share/elasticsearch

WORKDIR /usr/share/elasticsearch
COPY --from=builder --chown=1000:0 /usr/share/elasticsearch /usr/share/elasticsearch

# Replace OpenJDK's built-in CA certificate keystore with the one from the OS
# vendor. The latter is superior in several ways.
# REF: https://github.com/elastic/elasticsearch-docker/issues/171
RUN ln -sf /etc/pki/ca-trust/extracted/java/cacerts /usr/share/elasticsearch/jdk/lib/security/cacerts

ENV PATH /usr/share/elasticsearch/bin:$PATH

COPY bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod g=u /etc/passwd && \
    chmod 0775 /usr/local/bin/docker-entrypoint.sh

# Ensure that there are no files with setuid or setgid, in order to mitigate "stackclash" attacks.
RUN find / -xdev -perm -4000 -exec chmod ug-s {} +

EXPOSE 9200 9300

LABEL org.label-schema.build-date="2020-06-14T19:35:50.234439Z" \
  org.label-schema.license="Elastic-License" \
  org.label-schema.name="Elasticsearch" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.url="https://www.elastic.co/products/elasticsearch" \
  org.label-schema.usage="https://www.elastic.co/guide/en/elasticsearch/reference/index.html" \
  org.label-schema.vcs-ref="757314695644ea9a1dc2fecd26d1a43856725e65" \
  org.label-schema.vcs-url="https://github.com/elastic/elasticsearch" \
  org.label-schema.vendor="Elastic" \
  org.label-schema.version="$PACKAGE_VERSION" \
  org.opencontainers.image.created="2020-06-14T19:35:50.234439Z" \
  org.opencontainers.image.documentation="https://www.elastic.co/guide/en/elasticsearch/reference/index.html" \
  org.opencontainers.image.licenses="Elastic-License" \
  org.opencontainers.image.revision="757314695644ea9a1dc2fecd26d1a43856725e65" \
  org.opencontainers.image.source="https://github.com/elastic/elasticsearch" \
  org.opencontainers.image.title="Elasticsearch" \
  org.opencontainers.image.url="https://www.elastic.co/products/elasticsearch" \
  org.opencontainers.image.vendor="Elastic" \
  org.opencontainers.image.version="$PACKAGE_VERSION"

ENTRYPOINT ["/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["eswrapper"]

################################################################################
# End of multi-stage Dockerfile
################################################################################
