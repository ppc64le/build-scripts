FROM openjdk:8-jdk
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"
ENV TINI_VERSION 0.16.1

RUN groupadd neo4j && useradd -m -d /var/lib/neo4j -g neo4j neo4j

RUN apt-get update \
    && apt-get install maven gosu -y \
    && git clone https://github.com/neo4j/neo4j.git \
    && cd neo4j && git checkout 3.4.0 \
    && export MAVEN_OPTS="-Xmx512m" \
    && mvn clean install -DskipTests \
    && tar -zxvf packaging/standalone/target/neo4j-community-3.4.0-SNAPSHOT-unix.tar.gz --strip-components=1 -C /var/lib/neo4j \
    && cd .. && rm -rf neo4j \
    && mv /var/lib/neo4j/data /data \
    && chown -R neo4j:neo4j /data \
    && chmod -R 777 /data \
    && chown -R neo4j:neo4j /var/lib/neo4j \
    && chmod -R 777 /var/lib/neo4j \
    && ln -s /data /var/lib/neo4j/data \
    && curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-ppc64el -o /sbin/tini && chmod +x /sbin/tini \
    && apt-get purge --auto-remove maven -y 
     
ENV PATH /var/lib/neo4j/bin:$PATH
WORKDIR /var/lib/neo4j
VOLUME /data
COPY docker-entrypoint.sh /docker-entrypoint.sh
EXPOSE 7474 7473 7687
ENTRYPOINT ["/sbin/tini", "-g", "--", "/docker-entrypoint.sh"]
CMD ["neo4j", "start"]
