FROM registry.access.redhat.com/ubi9/ubi-minimal

ARG PACKAGE_VERSION=3.7.2
ARG JAVA_VERSION=11

RUN microdnf install -y java-${JAVA_VERSION}-openjdk \
    unzip \
    libcurl-devel

RUN curl https://archive.apache.org/dist/tinkerpop/${PACKAGE_VERSION}/apache-tinkerpop-gremlin-server-${PACKAGE_VERSION}-bin.zip -o /tmp/gremlin-server.zip \
    && unzip /tmp/gremlin-server.zip -d / \
    && rm -f /tmp/gremlin-server.zip

WORKDIR /apache-tinkerpop-gremlin-server-${PACKAGE_VERSION}

EXPOSE 8182

CMD ["bin/gremlin-server.sh", "conf/gremlin-server.yaml"]
