# NOTE: This is based on the original work at https://github.com/elastic/dockerfiles/

################################################################################
# This Dockerfile was generated from the template at distribution/src/docker/Dockerfile
#
# Beginning of multi stage Dockerfile
################################################################################

################################################################################
# Build stage 0 `builder`:
# Extract Elasticsearch artifact
################################################################################

ARG PACKAGE_VERSION=v8.19.13

FROM registry.access.redhat.com/ubi9/ubi:latest AS builder

ARG PACKAGE_VERSION
ARG PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/elasticsearch/elasticsearch_v8.19.13.patch
# `tini` is a tiny but valid init for containers. This is used to cleanly
# control how ES and any child processes are shut down.
#
# The tini GitHub page gives instructions for verifying the binary using
# gpg, but the keyservers are slow to return the key and this can fail the
# build. Instead, we check the binary against the published checksum.


# Install tini
RUN set -eux ; \
    tini_bin="" ; \
    case "$(arch)" in \
        aarch64) tini_bin='tini-arm64' ;; \
        x86_64)  tini_bin='tini-amd64' ;; \
        ppc64le) tini_bin='tini-ppc64le' ;; \
        *) echo >&2 "Unsupported architecture $(arch)" ; exit 1 ;; \
    esac ; \
    curl --retry 10 -S -L -O https://github.com/krallin/tini/releases/download/v0.19.0/${tini_bin} ; \
    curl --retry 10 -S -L -O https://github.com/krallin/tini/releases/download/v0.19.0/${tini_bin}.sha256sum ; \
    sha256sum -c ${tini_bin}.sha256sum ; \
    rm ${tini_bin}.sha256sum ; \
    mv ${tini_bin} /bin/tini ; \
    chmod +x /bin/tini

WORKDIR /opt

RUN yum update -y && \
    yum install -y wget git unzip tar gzip make gcc gcc-c++ patch libcurl-devel libzstd

################################################################################
# Install multiple JDKs (REQUIRED for ES 8.19.13 build)
################################################################################

# JDK 21 (used in runtime)
RUN wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.8%2B9/OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.8_9.tar.gz && \
    tar -C /opt -xf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.8_9.tar.gz && \
    rm -f OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.8_9.tar.gz

# Additional JDKs (same as script)
RUN for v in 17.0.8.1_1 18.0.2.1_1 19.0.2_7 20_36 22.0.2_9 23.0.2_7 24.0.2_12; do echo "Installing JDK $v"; done

RUN wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8.1+1/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.8.1_1.tar.gz && \
    tar -C /opt -xf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.8.1_1.tar.gz && rm -f *.tar.gz

RUN wget https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.2.1%2B1/OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.2.1_1.tar.gz && \
    tar -C /opt -xf OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.2.1_1.tar.gz && rm -f *.tar.gz

RUN wget https://github.com/adoptium/temurin19-binaries/releases/download/jdk-19.0.2%2B7/OpenJDK19U-jdk_ppc64le_linux_hotspot_19.0.2_7.tar.gz && \
    tar -C /opt -xf OpenJDK19U-jdk_ppc64le_linux_hotspot_19.0.2_7.tar.gz && rm -f *.tar.gz

RUN wget https://github.com/adoptium/temurin20-binaries/releases/download/jdk-20%2B36/OpenJDK20U-jdk_ppc64le_linux_hotspot_20_36.tar.gz && \
    tar -C /opt -xf OpenJDK20U-jdk_ppc64le_linux_hotspot_20_36.tar.gz && rm -f *.tar.gz

RUN wget https://github.com/adoptium/temurin22-binaries/releases/download/jdk-22.0.2%2B9/OpenJDK22U-jdk_ppc64le_linux_hotspot_22.0.2_9.tar.gz && \
    tar -C /opt -xf OpenJDK22U-jdk_ppc64le_linux_hotspot_22.0.2_9.tar.gz && rm -f *.tar.gz

RUN wget https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.2%2B7/OpenJDK23U-jdk_ppc64le_linux_hotspot_23.0.2_7.tar.gz && \
    tar -C /opt -xf OpenJDK23U-jdk_ppc64le_linux_hotspot_23.0.2_7.tar.gz && rm -f *.tar.gz

RUN wget https://github.com/adoptium/temurin24-binaries/releases/download/jdk-24.0.2%2B12/OpenJDK24U-jdk_ppc64le_linux_hotspot_24.0.2_12.tar.gz && \
    tar -C /opt -xf OpenJDK24U-jdk_ppc64le_linux_hotspot_24.0.2_12.tar.gz && rm -f *.tar.gz

################################################################################
# ENV setup 
################################################################################

ENV JAVA_HOME=/opt/jdk-21.0.8+9
ENV ES_JAVA_HOME=/opt/jdk-21.0.8+9
ENV PATH=$JAVA_HOME/bin:$PATH \
    LANG=en_US.UTF-8 \
    JDK17_HOME=/opt/jdk-17.0.8.1+1 \
    JDK18_HOME=/opt/jdk-18.0.2.1+1 \
    JDK19_HOME=/opt/jdk-19.0.2+7 \
    JDK20_HOME=/opt/jdk-20+36 \
    JDK21_HOME=/opt/jdk-21.0.8+9 \
    JDK22_HOME=/opt/jdk-22.0.2+9 \
    JDK23_HOME=/opt/jdk-23.0.2+7 \
    JDK24_HOME=/opt/jdk-24.0.2+12

################################################################################
# Clone + Patch + Build
################################################################################

COPY elasticsearch_v8.19.13.patch /root/elasticsearch_v8.19.13.patch

RUN git clone https://github.com/elastic/elasticsearch.git && \
    cd elasticsearch && \
    git checkout ${PACKAGE_VERSION} && \
    git apply ${PATCH##*/} && \
    mkdir -p \
      distribution/archives/linux-ppc64le-tar \
      distribution/archives/oss-linux-ppc64le-tar \
      distribution/docker/cloud-ess-docker-ppc64le-export \
      distribution/archives/no-jdk-darwin-ppc64le-tar \
      distribution/docker/ubi-docker-ppc64le-export \
      distribution/packages/ppc64le-deb \
      distribution/docker/ironbank-docker-ppc64le-export \
      distribution/docker/docker-ppc64le-export \
      distribution/packages/ppc64le-rpm \
      distribution/archives/darwin-ppc64le-tar \
      distribution/docker/cloud-docker-ppc64le-export && \
    ./gradlew :spotlessApply && \
    ./gradlew :distribution:archives:linux-ppc64le-tar:assemble --parallel \
        -x compileMain25Java -x compileMain26Java && \
    mv distribution/archives/linux-ppc64le-tar/build/distributions/*.tar.gz /opt


RUN mkdir /usr/share/elasticsearch
WORKDIR /usr/share/elasticsearch

RUN tar -zxf /opt/elasticsearch-*.tar.gz --strip-components=1

# Create required directories for native libraries
RUN mkdir -p /usr/share/elasticsearch/libs/native/libraries/build/platform/linux-ppc64le && \
    mkdir -p /usr/share/elasticsearch/lib/platform/linux-ppc64le

# Copy libzstd.so from system to Elasticsearch native library directories
RUN cp /usr/lib64/libzstd.so.1 /usr/share/elasticsearch/libs/native/libraries/build/platform/linux-ppc64le/libzstd.so && \
    cp /usr/lib64/libzstd.so.1 /usr/share/elasticsearch/lib/platform/linux-ppc64le/libzstd.so

# Set correct permissions so Elasticsearch can access it
RUN chmod 755 /usr/share/elasticsearch/libs/native/libraries/build/platform/linux-ppc64le/libzstd.so && \
    chmod 755 /usr/share/elasticsearch/lib/platform/linux-ppc64le/libzstd.so

# Verify that libzstd.so is copied correctly
#RUN ls -l /usr/share/elasticsearch/libs/native/libraries/build/platform/linux-ppc64le/ && \
#    ls -l /usr/share/elasticsearch/lib/platform/linux-ppc64le/ && \
#    exit 1

#RUN cd lib && \
#    rm -rf jna-* && \
#    wget https://repo1.maven.org/maven2/net/java/dev/jna/jna/5.7.0/jna-5.7.0.jar

# The distribution includes a `config` directory, no need to create it

COPY config/elasticsearch.yml config/
COPY config/log4j2.properties config/log4j2.docker.properties

# 1. Configure the distribution for Docker
# 2. Ensure directories are created. Most already are, but make sure
# 3. Apply correct permissions
# 4. Move the distribution's default logging config aside
# 5. Generate a docker logging config, to be used by default
# 6. Apply more correct permissions
# 7. The JDK's directories' permissions don't allow `java` to be executed under a different
#    group to the default. Fix this.
# 8. Ensure that there are no files with setuid or setgid, in order to mitigate "stackclash" attacks.
# 9. Ensure all files are world-readable by default. It should be possible to
#    examine the contents of the image under any UID:GID


RUN sed -i -e 's/ES_DISTRIBUTION_TYPE=tar/ES_DISTRIBUTION_TYPE=docker/' bin/elasticsearch-env && \
    mkdir -p config/jvm.options.d data logs plugins && \
    chmod 0775 config config/jvm.options.d data logs plugins && \
    mv config/log4j2.properties config/log4j2.file.properties && \
    mv config/log4j2.docker.properties config/log4j2.properties && \
    chmod 0660 config/elasticsearch.yml config/log4j2*.properties && \
    find ./jdk -type d -exec chmod 0755 {} + && \
    find . -xdev -perm -4000 -exec chmod ug-s {} + && \
    find . -type f -exec chmod o+r {} +

# Build stage 1 (the actual Elasticsearch image):
#
# Copy elasticsearch from stage 0
# Add entrypoint
################################################################################

FROM registry.access.redhat.com/ubi9/ubi:latest

ARG PACKAGE_VERSION

RUN for iter in {1..10}; do \
    yum update --setopt=tsflags=nodocs -y && \
    yum install --setopt=tsflags=nodocs -y \
    shadow-utils zip unzip procps-ng && \
    yum clean all && \
    exit_code=0 && break || \
    exit_code=$? && echo "yum error: retry $iter in 10s" && sleep 10; \
    done; \
    exit $exit_code

RUN groupadd -g 1000 elasticsearch && \
    adduser -u 1000 -g 1000 -G 0 -d /usr/share/elasticsearch elasticsearch && \
    chmod 0775 /usr/share/elasticsearch && \
    chown -R 1000:0 /usr/share/elasticsearch

ENV ELASTIC_CONTAINER true

WORKDIR /usr/share/elasticsearch
COPY --from=builder --chown=1000:0 /usr/share/elasticsearch /usr/share/elasticsearch
COPY --from=builder --chown=0:0 /bin/tini /bin/tini

ENV PATH /usr/share/elasticsearch/bin:$PATH
COPY bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# 1. Sync the user and group permissions of /etc/passwd
# 2. Set correct permissions of the entrypoint
# 3. Ensure that there are no files with setuid or setgid, in order to mitigate "stackclash" attacks.
#    We've already run this in previous layers so it ought to be a no-op.
# 4. Replace OpenJDK's built-in CA certificate keystore with the one from the OS
#    vendor. The latter is superior in several ways.
#    REF: https://github.com/elastic/elasticsearch-docker/issues/171
RUN chmod g=u /etc/passwd && \
    chmod 0775 /usr/local/bin/docker-entrypoint.sh && \
    find / -xdev -perm -4000 -exec chmod ug-s {} + && \
    ln -sf /etc/pki/ca-trust/extracted/java/cacerts /usr/share/elasticsearch/jdk/lib/security/cacerts

EXPOSE 9200 9300

LABEL org.label-schema.build-date="2022-03-28T17:35:51.740591902Z" \
    org.label-schema.license="Elastic-License-2.0" \
    org.label-schema.name="Elasticsearch" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://www.elastic.co/products/elasticsearch" \
    org.label-schema.usage="https://www.elastic.co/guide/en/elasticsearch/reference/index.html" \
    org.label-schema.vcs-ref="de7261de50d90919ae53b0eff9413fd7e5307301" \
    org.label-schema.vcs-url="https://github.com/elastic/elasticsearch" \
    org.label-schema.vendor="Elastic" \
    org.label-schema.version="$PACKAGE_VERSION" \
    org.opencontainers.image.created="2022-03-28T17:35:51.740591902Z" \
    org.opencontainers.image.documentation="https://www.elastic.co/guide/en/elasticsearch/reference/index.html" \
    org.opencontainers.image.licenses="Elastic-License-2.0" \
    org.opencontainers.image.revision="de7261de50d90919ae53b0eff9413fd7e5307301" \
    org.opencontainers.image.source="https://github.com/elastic/elasticsearch" \
    org.opencontainers.image.title="Elasticsearch" \
    org.opencontainers.image.url="https://www.elastic.co/products/elasticsearch" \
    org.opencontainers.image.vendor="Elastic" \
    org.opencontainers.image.version="$PACKAGE_VERSION"

ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["eswrapper"]

USER 1000:0
################################################################################
# End of multi-stage Dockerfile

