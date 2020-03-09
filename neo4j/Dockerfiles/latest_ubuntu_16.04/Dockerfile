FROM adoptopenjdk/maven-openjdk8 as build-stage
COPY neo4j /neo4j

WORKDIR /neo4j

RUN export MAVEN_OPTS="-Xmx512m" \
    && mvn -X clean install -DskipTests -Dlicensing.skip=true


FROM ppc64le/openjdk:8-jdk
ENV TINI_VERSION 0.16.1

COPY --from=build-stage /neo4j/packaging/standalone/target/neo4j-community-3.5.11-SNAPSHOT-unix.tar.gz /neo4j-community-3.5.11-SNAPSHOT-unix.tar.gz

RUN groupadd neo4j && useradd -m -d /var/lib/neo4j -g neo4j neo4j

RUN apt-get update \
    && apt-get install gosu -y

RUN tar -zxvf /neo4j-community-3.5.11-SNAPSHOT-unix.tar.gz --strip-components=1 -C /var/lib/neo4j \
    && cd .. && rm -rf neo4j \
    && mv /var/lib/neo4j/data /data \
    && chown -R neo4j:neo4j /data \
    && chmod -R 777 /data \
    && chown -R neo4j:neo4j /var/lib/neo4j \
    && chmod -R 777 /var/lib/neo4j \
    && ln -s /data /var/lib/neo4j/data \
    && curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-ppc64el -o /sbin/tini && chmod +x /sbin/tini
     
ENV PATH /var/lib/neo4j/bin:$PATH
WORKDIR /var/lib/neo4j
VOLUME /data
COPY docker-entrypoint.sh /docker-entrypoint.sh
EXPOSE 7474 7473 7687
ENTRYPOINT /bin/bash /docker-entrypoint.sh
CMD ["neo4j", "start"]
