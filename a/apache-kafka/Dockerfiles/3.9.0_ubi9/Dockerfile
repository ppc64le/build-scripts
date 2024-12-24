FROM registry.access.redhat.com/ubi9/ubi:9.3 as builder

ARG PACKAGE_VERSION=3.9.0

RUN yum install -y git make wget gcc-c++ && \
    wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.9%2B9/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz && \
    tar -C /usr/local -zxf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz && \
    ln -sf /usr/local/jdk-17.0.9+9/bin/java /usr/bin/java && \
    rm -f OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz

RUN git clone https://github.com/apache/kafka && \
    cd kafka && \
    git checkout $PACKAGE_VERSION && \
    ./gradlew jar

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

EXPOSE 9092

ENV KAFKA_HOME=/opt/kafka
ENV PATH=$PATH:$KAFKA_HOME/bin
ENV JAVA_HOME=/usr/local/jdk-17.0.9+9

RUN microdnf install -y bash && \
    microdnf clean all && \
    mkdir -p /etc/kafka/docker /mnt/shared/config /opt/kafka/config /etc/kafka/secrets && \
    useradd -m -d /home/appuser -s /bin/bash appuser && \
    chown -R appuser:root /etc/kafka /opt/kafka /mnt/shared/config && \
    chmod -R ug+w /etc/kafka /opt/kafka /mnt/shared/config

# Copy Kafka binaries and configuration files from the builder stage
COPY --from=builder /kafka /opt/kafka/
COPY --from=builder /usr/local/jdk-17.0.9+9 /usr/local/jdk-17.0.9+9
COPY --from=builder /kafka/config/kraft/reconfig-server.properties /etc/kafka/docker/
COPY --from=builder /kafka/config/log4j.properties /etc/kafka/docker/
COPY --from=builder /kafka/config/tools-log4j.properties /etc/kafka/docker/
COPY --from=builder /kafka/bin/* /opt/kafka/bin/

CMD ["/opt/kafka/bin/kafka-server-start.sh", "/opt/kafka/config/server.properties"]