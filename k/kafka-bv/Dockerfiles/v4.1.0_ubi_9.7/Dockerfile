# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# Stage 1: Build utilities from source using secure Go version (resolves stdlib CVEs)
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS setupbuilder

ARG KAFKA_VERSION=4.1.0
ARG BITNAMI_COMMIT=be4c353
ARG GO_VERSION=1.26.3


# Install build dependencies and update system packages
RUN yum update -y && yum install -y git wget tar gcc && yum clean all

# Install secure Go version to fix stdlib CVEs (CVE-2025-68121, CVE-2025-58183, etc.)
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm go${GO_VERSION}.linux-ppc64le.tar.gz

ENV PATH="/usr/local/go/bin:$PATH"

# Build wait-for-port from source
RUN git clone https://github.com/bitnami/wait-for-port /build/wait-for-port && \
    cd /build/wait-for-port && \
    git checkout v1.0.10 && \
    go build .


# Assemble prebuildfs
RUN git clone https://github.com/bitnami/containers /build/containers && \
    cd /build/containers && \
    git checkout ${BITNAMI_COMMIT}

RUN cd /build/containers/bitnami/kafka/4.1/debian-12 && \
    wget https://downloads.bitnami.com/files/stacksmith/kafka-${KAFKA_VERSION}-0-linux-amd64-debian-12.tar.gz || true && \
    if [ -f kafka-${KAFKA_VERSION}-0-linux-amd64-debian-12.tar.gz ]; then \
        tar -xvf kafka-${KAFKA_VERSION}-0-linux-amd64-debian-12.tar.gz && \
        mkdir -p prebuildfs/opt/bitnami/kafka/config && \
        if [ -d kafka-${KAFKA_VERSION}-linux-amd64-debian-12/files/kafka/config ]; then \
            cp -r kafka-${KAFKA_VERSION}-linux-amd64-debian-12/files/kafka/config/* \
               prebuildfs/opt/bitnami/kafka/config/; \
        fi; \
    fi

# Stage 2: Build Kafka from source
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS kafkabuilder

ARG KAFKA_VERSION=4.1.0

WORKDIR /build

RUN yum update -y && \
    yum install -y \
    git \
    wget \
    tar \
    gcc \
    gcc-c++ \
    make \
    java-17-openjdk-devel.ppc64le \
    libtool \
    file \
    diffutils && \
    yum clean all && \
    rm -rf /var/cache/yum

# Build Kafka with CVE fixes for vulnerable dependencies
RUN cd /build && \
    git clone https://github.com/apache/kafka && \
    cd kafka && \
    git checkout ${KAFKA_VERSION} && \
    echo "Checked out Kafka version: ${KAFKA_VERSION}" && \
    git describe --tags && \
    export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)') && \
    export PATH=$JAVA_HOME/bin:$PATH && \
    echo 'allprojects {' > init.gradle && \
    echo '    configurations.all {' >> init.gradle && \
    echo '        resolutionStrategy {' >> init.gradle && \
    echo "            force 'commons-io:commons-io:2.21.0'" >> init.gradle && \
    echo "            force 'org.apache.httpcomponents.client5:httpclient5:5.6.1'" >> init.gradle && \
    echo "            force 'org.bouncycastle:bcpg-jdk18on:1.84'" >> init.gradle && \
    echo "            force 'org.bouncycastle:bcprov-jdk18on:1.84'" >> init.gradle && \
    echo "            force 'org.codehaus.plexus:plexus-utils:4.0.3'" >> init.gradle && \
    echo "            force 'org.eclipse.jetty:jetty-http:12.0.33'" >> init.gradle && \
    echo "            force 'org.eclipse.jetty:jetty-server:12.0.33'" >> init.gradle && \
    echo "            force 'org.eclipse.jetty:jetty-io:12.0.33'" >> init.gradle && \
    echo "            force 'org.eclipse.jetty:jetty-util:12.0.33'" >> init.gradle && \
    echo "            force 'org.eclipse.jetty:jetty-client:12.0.33'" >> init.gradle && \
    echo '        }' >> init.gradle && \
    echo '    }' >> init.gradle && \
    echo '}' >> init.gradle && \
    ./gradlew jar -x test --init-script init.gradle

# Collect Kafka binaries and libraries
RUN mkdir -p /root/kafka/bin /root/kafka/libs /root/kafka/config && \
    cp -r /build/kafka/bin/* /root/kafka/bin/ && \
    cp -r /build/kafka/config/* /root/kafka/config/ && \
    find /build/kafka -path "*/build/libs/*.jar" -type f -exec cp {} /root/kafka/libs/ \; && \
    find /build/kafka -path "*/build/dependant-libs/*.jar" -type f -exec cp {} /root/kafka/libs/ \; 2>/dev/null || true && \
    find /build/kafka -path "*/build/dependant-libs-*/*.jar" -type f -exec cp {} /root/kafka/libs/ \; 2>/dev/null || true && \
    find /root/.gradle/caches/modules-2/files-2.1 -name "*.jar" -exec cp {} /root/kafka/libs/ \; 2>/dev/null || true && \
    echo "Total JARs before cleanup: $(ls -1 /root/kafka/libs/*.jar | wc -l)" && \
    cd /root/kafka/libs && \
    rm -f commons-io-2.11.0.jar commons-io-2.8.0.jar || true && \
    rm -f httpclient5-5.6.jar || true && \
    rm -f bcpg-jdk18on-1.71.jar bcpg-jdk18on-1.83.jar || true && \
    rm -f bcprov-jdk18on-1.71.jar bcprov-jdk18on-1.83.jar bcprov-jdk15on-1.56.jar || true && \
    rm -f plexus-utils-4.0.2.jar plexus-utils-3.*.jar || true && \
    rm -f jetty-http-12.0.22.jar jetty-server-12.0.22.jar jetty-io-12.0.22.jar || true && \
    rm -f jetty-util-12.0.22.jar jetty-client-12.0.22.jar || true && \
    rm -f jackson-core-2.14.2.jar jackson-databind-2.14.2.jar jackson-annotations-2.14.2.jar || true && \
    rm -f jackson-dataformat-yaml-2.14.2.jar jackson-module-afterburner-2.14.2.jar jackson-module-blackbird-2.14.2.jar || true && \
    rm -f ehcache-2.10.4.jar || true && \
    rm -f h2-2.1.214.jar || true && \
    rm -f xstream-1.4.20.jar || true && \
    rm -f snakeyaml-1.33.jar || true && \
    rm -f lz4-java-1.8.0.jar || true && \
    rm -f mina-core-2.0.16.jar || true && \
    rm -f velocity-engine-core-2.3.jar || true && \
    rm -f commons-beanutils-1.9.4.jar || true && \
    ls -lh /root/kafka/libs/ && \
    echo "Total JARs after cleanup: $(ls -1 /root/kafka/libs/*.jar | wc -l)"

# Stage 3: Final runtime image
FROM registry.access.redhat.com/ubi9/ubi:9.7

LABEL com.vmware.cp.artifact.flavor="sha256:c50c90cfd9d12b445b011e6ad529f1ad3daea45c26d20b00732fae3cd71f6a83" \
      org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/kafka/README.md" \
      org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/kafka" \
      org.opencontainers.image.title="kafka" \
      org.opencontainers.image.version="4.1.0"

ENV HOME="/" \
    OS_ARCH="ppc64le" \
    OS_FLAVOUR="rhel9" \
    OS_NAME="linux"

COPY --from=setupbuilder /build/containers/bitnami/kafka/4.1/debian-12/prebuildfs /
COPY --from=setupbuilder /build/containers/bitnami/kafka/4.1/debian-12/rootfs /

# Install runtime dependencies and apply all security updates
# Fix HIGH CVEs with available patches: libcap (CVE-2026-4878), vim-minimal (CVE-2026-34982)
RUN yum update -y && \
    yum install -y \
    acl \
    ca-certificates \
    curl-minimal \
    gzip \
    glibc \
    procps-ng \
    tar \
    java-17-openjdk-headless.ppc64le \
    zlib && \
    yum upgrade -y --allowerasing && \
    yum upgrade -y libcap vim-minimal && \
    yum clean all && \
    rm -rf /var/cache/yum /var/tmp/*

# Set Java environment for runtime (dynamically detect)
RUN export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)' | head -1) && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile.d/java.sh && \
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile.d/java.sh

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

RUN chmod g+rwX /opt/bitnami
RUN mkdir -p /opt/bitnami/common/bin /opt/bitnami/kafka

# Copy Kafka artifacts first (before postunpack scripts)
COPY --from=setupbuilder /build/wait-for-port/wait-for-port /opt/bitnami/common/bin/wait-for-port
COPY --from=kafkabuilder /root/kafka/bin /opt/bitnami/kafka/bin
COPY --from=kafkabuilder /root/kafka/libs /opt/bitnami/kafka/libs
COPY --from=kafkabuilder /root/kafka/config /opt/bitnami/kafka/config

# Now run postunpack scripts
RUN ln -s /opt/bitnami/scripts/kafka/entrypoint.sh /entrypoint.sh
RUN ln -s /opt/bitnami/scripts/kafka/run.sh /run.sh
RUN /opt/bitnami/scripts/java/postunpack.sh
RUN /opt/bitnami/scripts/kafka/postunpack.sh
RUN chmod g+rwX /opt/bitnami

# Set executable permissions
RUN chmod +x /opt/bitnami/common/bin/wait-for-port && \
    chmod +x /opt/bitnami/kafka/bin/*.sh

# Create symlink for Java compatibility
RUN mkdir -p /opt/bitnami/java/bin && \
    REAL_JAVA_HOME=$(ls -d /usr/lib/jvm/java-17-openjdk-* | head -1) && \
    ln -s $REAL_JAVA_HOME /opt/bitnami/java/jre && \
    ln -s $REAL_JAVA_HOME/bin/java /opt/bitnami/java/bin/java

ENV APP_VERSION="4.1.0" \
    BITNAMI_APP_NAME="kafka" \
    IMAGE_REVISION="0" \
    JAVA_HOME="/opt/bitnami/java" \
    PATH="/opt/bitnami/java/bin:/opt/bitnami/common/bin:/opt/bitnami/kafka/bin:$PATH"

EXPOSE 9092

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/kafka/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/kafka/run.sh" ]
