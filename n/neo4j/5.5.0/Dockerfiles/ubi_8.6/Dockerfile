FROM registry.access.redhat.com/ubi8/ubi:8.6
MAINTAINER "Sumit Dubey <sumit.dubey2@ibm.com>"
ENV TINI_VERSION 0.19.0
ENV GOSU_VERSION=1.16
ENV NEO4J_VERSION=5.5.0
ENV MAVEN_VERSION=3.9.0
ENV NEO4J_HOME="/var/lib/neo4j"
ENV NEO4J_EDITION=community

RUN groupadd --gid 7474 --system neo4j && useradd --uid 7474 --system --no-create-home --home /var/lib/neo4j -g neo4j neo4j

RUN yum install java-17-openjdk-devel git wget curl jq -y \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-ppc64el" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && export CWD=$(pwd) \
    && wget https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && tar xvf apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && rm -rf apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && export PATH=$CWD/apache-maven-${MAVEN_VERSION}/bin:$PATH \
    && git clone https://github.com/neo4j/neo4j.git \
    && cd neo4j && git checkout ${NEO4J_VERSION} \
    && export MAVEN_OPTS="-Xmx4096m" \
    && sed -i.bak '276d' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java \
    && sed -i '276i \ \ \ \ \ \ \ \ \ \ \ \ if (bufferAlignment == UnsafeUtil.pageSize()) {' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java \
    && sed -i '277i \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ address = memoryAllocator.allocateAligned(getCachePageSize(), getCachePageSize());' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java \
    && sed -i '278i \ \ \ \ \ \ \ \ \ \ \ \ } else {' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java \
    && sed -i '279i \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ address = memoryAllocator.allocateAligned(getCachePageSize(), bufferAlignment);' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java \
    && sed -i '280i \ \ \ \ \ \ \ \ \ \ \ \ }' ./community/io/src/main/java/org/neo4j/io/pagecache/impl/muninn/PageList.java \
    && mvn clean install -DskipTests \
    && mkdir -p /var/lib/neo4j \
    && tar --extract --file packaging/standalone/target/neo4j-community-${NEO4J_VERSION}-SNAPSHOT-unix.tar.gz --directory /var/lib/neo4j --strip-components=1 \
    && sed -i "$ a server.config.strict_validation.enabled=false" /var/lib/neo4j/conf/neo4j.conf \
    && cd .. && rm -rf neo4j \
    && mv /var/lib/neo4j/data /data \
    && mv /var/lib/neo4j/logs /logs \
    && chown -R neo4j:neo4j /data \
    && chmod -R 777 /data \
    && chown -R neo4j:neo4j /logs \
    && chmod -R 777 /logs \
    && chown -R neo4j:neo4j /var/lib/neo4j \
    && chmod -R 777 /var/lib/neo4j \
    && ln -s /data /var/lib/neo4j/data \
    && ln -s /logs /var/lib/neo4j/logs \
    && curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-ppc64el -o /sbin/tini && chmod +x /sbin/tini \
    && rm -rf $CWD/apache-maven-${MAVEN_VERSION} \
    && yum remove git wget -y

ENV PATH /var/lib/neo4j/bin:$PATH
WORKDIR /var/lib/neo4j
VOLUME /data /logs
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
EXPOSE 7474 7473 7687
ENTRYPOINT ["/sbin/tini", "-g", "--", "/docker-entrypoint.sh"]
CMD ["neo4j"]