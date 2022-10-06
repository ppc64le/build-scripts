FROM registry.access.redhat.com/ubi8/ubi:8.5 AS builder

ARG JANUS_VERSION=0.6.2
ARG YQ_VERSION=3.4.1

ENV JANUS_VERSION=${JANUS_VERSION} \
    JANUS_HOME=/opt/janusgraph

WORKDIR /opt

RUN yum update -y && \
    yum install -y gpg unzip curl && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/janusgraph-${JANUS_VERSION}.zip -o janusgraph.zip && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/janusgraph-${JANUS_VERSION}.zip.asc -o janusgraph.zip.asc && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/KEYS -o KEYS && \
    curl -fSL -# https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_ppc64le -o yq && \
    gpg --import KEYS && \
    gpg --batch --verify janusgraph.zip.asc janusgraph.zip && \
    unzip janusgraph.zip && \
    mv janusgraph-${JANUS_VERSION} /opt/janusgraph && \
    rm -rf ${JANUS_HOME}/elasticsearch && \
    rm -rf ${JANUS_HOME}/javadocs && \
    rm -rf ${JANUS_HOME}/log && \
    rm -rf ${JANUS_HOME}/examples && \
    rm -rf ${JANUS_HOME}/conf/janusgraph-*.properties && \
    rm -rf ${JANUS_HOME}/conf/gremlin-server

COPY conf/ ${JANUS_HOME}/conf/
COPY scripts/remote-connect.groovy ${JANUS_HOME}/scripts/

FROM registry.access.redhat.com/ubi8/ubi:8.5

RUN  yum install -y java-1.8.0-openjdk-devel

ARG CREATED=test
ARG REVISION=test
ARG JANUS_VERSION=0.6.2

ENV JANUS_VERSION=${JANUS_VERSION} \
    JANUS_HOME=/opt/janusgraph \
    JANUS_CONFIG_DIR=/etc/opt/janusgraph \
    JANUS_DATA_DIR=/var/lib/janusgraph \
    JANUS_SERVER_TIMEOUT=30 \
    JANUS_STORAGE_TIMEOUT=60 \
    JANUS_PROPS_TEMPLATE=berkeleyje-lucene \
    JANUS_INITDB_DIR=/docker-entrypoint-initdb.d \
    gremlinserver.graphs.graph=/etc/opt/janusgraph/janusgraph.properties \
    gremlinserver.threadPoolWorker=1 \
    gremlinserver.gremlinPool=8

RUN  groupadd -r janusgraph --gid=9999
RUN  useradd -r -g janusgraph --uid=9999 -d ${JANUS_DATA_DIR} janusgraph
RUN  yum update -y && \
    yum install -y krb5-devel.ppc64le && \
    yum install -y krb5-libs.ppc64le && \
    yum install -y krb5-workstation.ppc64le && \
    yum install -y libkadm5.ppc64le && \
    rm -rf /var/lib/apt/lists/*


COPY --from=builder /opt/janusgraph/ /opt/janusgraph/
COPY --from=builder /opt/yq /usr/bin/yq
COPY docker-entrypoint.sh /usr/local/bin/
COPY load-initdb.sh /usr/local/bin/

RUN chmod 755 /usr/local/bin/docker-entrypoint.sh && \
    chmod 755 /usr/local/bin/load-initdb.sh && \
    chmod 755 /usr/bin/yq && \
    mkdir -p ${JANUS_INITDB_DIR} ${JANUS_CONFIG_DIR} ${JANUS_DATA_DIR} && \
    chown -R janusgraph:janusgraph ${JANUS_HOME} ${JANUS_INITDB_DIR} ${JANUS_CONFIG_DIR} ${JANUS_DATA_DIR}
EXPOSE 8182

WORKDIR ${JANUS_HOME}
USER janusgraph

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "janusgraph" ]

LABEL org.opencontainers.image.title="JanusGraph Docker Image" \
      org.opencontainers.image.description="Official JanusGraph Docker image" \
      org.opencontainers.image.url="https://janusgraph.org/" \
      org.opencontainers.image.documentation="https://docs.janusgraph.org/v0.6/" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.source="https://github.com/JanusGraph/janusgraph-docker/" \
      org.opencontainers.image.vendor="JanusGraph" \
      org.opencontainers.image.version="${JANUS_VERSION}" \
      org.opencontainers.image.created="${CREATED}" \
      org.opencontainers.image.license="Apache-2.0"

