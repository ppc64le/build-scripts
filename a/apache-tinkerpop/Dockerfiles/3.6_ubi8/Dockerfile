FROM registry.access.redhat.com/ubi8/ubi-minimal

ARG TINKERPOP_VERSION=3.6.2
ARG JAVA_VERSION=11


RUN microdnf install java-${JAVA_VERSION}-openjdk \
    unzip \
    curl

RUN curl https://archive.apache.org/dist/tinkerpop/${TINKERPOP_VERSION}/apache-tinkerpop-gremlin-server-${TINKERPOP_VERSION}-bin.zip -o /tmp/gremlin-server.zip \
    && unzip /tmp/gremlin-server.zip -d / \
    && rm -f /tmp/gremlin-server.zip

WORKDIR /apache-tinkerpop-gremlin-server-${TINKERPOP_VERSION}

EXPOSE 8182

CMD ["bin/gremlin-server.sh", "conf/gremlin-server.yaml"]

