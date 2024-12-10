##############
# This Dockerfile is adopted from https://github.com/wurstmeister/kafka-docker/blob/master/Dockerfile
##############
FROM ibmcom/docker-ppc64le:18.06.3_ubi7

ARG kafka_version=2.6.0
ARG scala_version=2.13
ARG glibc_version=2.31-r0
ARG vcs_ref=unspecified
ARG build_date=unspecified

###Required Labels
LABEL name="kafka" \
      maintainer="sethp@us.ibm.com" \
      vendor="kafka" \
      version="${kafka_version}" \
      release="1" \
      summary="Red Hat UBI kafka" \
      description="Red Hat UBI kafka Application" \
      org.label-schema.name="kafka" \
      org.label-schema.description="Apache Kafka" \
      org.label-schema.build-date="${build_date}" \
      org.label-schema.vcs-url="https://github.com/ppc64le/build-scripts/tree/master/k/kafka/Dockerfiles/" \
      org.label-schema.vcs-ref="${vcs_ref}" \
      org.label-schema.version="${scala_version}_${kafka_version}" \
      org.label-schema.schema-version="1.0" 

RUN groupadd kafka && useradd -r -g kafka kafka -m -d /home/kafka/

ENV KAFKA_VERSION=$kafka_version \
    SCALA_VERSION=$scala_version \
    KAFKA_HOME=/opt/kafka \
    GLIBC_VERSION=$glibc_version

ENV PATH=${PATH}:${KAFKA_HOME}/bin

COPY download-kafka.sh start-kafka.sh broker-list.sh create-topics.sh versions.sh /tmp/

RUN yum install -y curl wget gcc make automake net-tools hostname \
 && wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-1.5.tar.gz \
 && tar -xvzf jq-1.5.tar.gz \
 && cd jq-1.5/ \
 && ./configure && make && make install \
 && chmod a+x /tmp/*.sh \
 && mv /tmp/start-kafka.sh /tmp/broker-list.sh /tmp/create-topics.sh /tmp/versions.sh /usr/bin \
 && sync && /tmp/download-kafka.sh \
 && tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt \
 && rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
 && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME} \
 && rm /tmp/* \
 && mkdir /licenses && cp /opt/kafka/LICENSE /licenses/licensing.txt \
 && chmod -R 777 /opt/kafka/ \
 && mkdir /kafka && chmod -R 777 /kafka/


COPY overrides /opt/overrides
VOLUME ["/kafka"]

USER kafka

# Use "exec" form so that it runs as PID 1 (useful for graceful shutdown)
CMD ["start-kafka.sh"]
