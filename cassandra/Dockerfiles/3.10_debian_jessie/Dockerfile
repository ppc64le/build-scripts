FROM ppc64le/openjdk:8
ENV GOSU_VERSION 1.7

RUN groupadd -r cassandra --gid=999 && useradd -r -g cassandra --uid=999 cassandra \
        && set -x \
        && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
        && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
        && export GNUPGHOME="$(mktemp -d)" \
        && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
        && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
        && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
        && chmod +x /usr/local/bin/gosu \
        && gosu nobody true \
        && apt-get update && apt-get install -y --no-install-recommends libjemalloc1 && rm -rf /var/lib/apt/lists/* \
        && { \
                echo 'Package: openjdk-* ca-certificates-java'; \
                echo 'Pin: release n=*-backports'; \
                echo 'Pin-Priority: 990'; \
        } > /etc/apt/preferences.d/java-backports


# https://wiki.apache.org/cassandra/DebianPackaging#Adding_Repository_Keys
ENV GPG_KEYS \
# gpg: key 0353B12C: public key "T Jake Luciani <jake@apache.org>" imported
        514A2AD631A57A16DD0047EC749D6EEC0353B12C \
# gpg: key FE4B2BDA: public key "Michael Shuler <michael@pbandjelly.org>" imported
        A26E528B271F19B9E5D8E19EA278B781FE4B2BDA
ENV CASSANDRA_VERSION 3.10

RUN set -ex; \
        export GNUPGHOME="$(mktemp -d)"; \
        for key in $GPG_KEYS; do \
                gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
        done; \
        gpg --export $GPG_KEYS > /etc/apt/trusted.gpg.d/cassandra.gpg; \
        rm -r "$GNUPGHOME"; \
        apt-key list \
    && wget http://mirror.fibergrid.in/apache/cassandra/3.10/apache-cassandra-3.10-bin.tar.gz && \
    tar -zxvf apache-cassandra-3.10-bin.tar.gz -C / 
     

COPY jvm.options /apache-cassandra-3.10/conf
COPY cassandra /apache-cassandra-3.10/bin
COPY jna-4.3.0.jar /apache-cassandra-3.10/lib
ENV PATH $PATH:/apache-cassandra-3.10/bin
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-ppc64el
ENV PATH $PATH:$JAVA_HOME/bin

RUN rm -rf /apache-cassandra-3.10/lib/jna-4.0.0.jar \
    && chown -R cassandra:cassandra /apache-cassandra-3.10 \
    && sed -ri 's/^(JVM_PATCH_VERSION)=.*/\1=25/' /apache-cassandra-3.10/conf/cassandra-env.sh \
    && mkdir -p /apache-cassandra-3.10/data/data && chown -R cassandra /apache-cassandra-3.10


ENV CASSANDRA_CONFIG /apache-cassandra-3.10/conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
VOLUME /apache-cassandra-3.10/data/data
EXPOSE 7000 7001 7199 9042 9160
CMD ["cassandra", "-f"]



