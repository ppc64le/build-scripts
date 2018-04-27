# vim:set ft=dockerfile:
FROM ppc64le/ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql
# add gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove ca-certificates wget \
	&& mkdir /docker-entrypoint-initdb.d

# install "pwgen" for randomizing passwords
RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		pwgen \
	&& rm -rf /var/lib/apt/lists/*

#Install At10

ENV PATH /opt/at10.0/bin:$PATH

ENV MARIADB_VERSION 10.2.14

RUN apt-get update && apt-get install -y make cmake libgnutls-dev git wget tzdata libncurses5-dev bison \
	&& wget ftp://ftp.unicamp.br/pub/linuxpatch/toolchain/at/ubuntu/dists/precise/6976a827.gpg.key \
	&& apt-key add 6976a827.gpg.key \
        && echo deb ftp://ftp.unicamp.br/pub/linuxpatch/toolchain/at/ubuntu xenial at10.0 >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -y advance-toolchain-at10.0-runtime advance-toolchain-at10.0-devel advance-toolchain-at10.0-perf advance-toolchain-at10.0-mcore-libs \
#Install Mariadb
	&& git clone https://github.com/MariaDB/server.git && cd server && git checkout mariadb-$MARIADB_VERSION \
	&& BUILD/autorun.sh && ./configure && make && make package \
 	&& cp mariadb-$MARIADB_VERSION-linux-ppc64le.tar.gz /usr/local/ \
	&& cd /usr/local/ \
	&& tar -zxvpf mariadb-$MARIADB_VERSION-linux-ppc64le.tar.gz \
	&& ln -s mariadb-$MARIADB_VERSION-linux-ppc64le mysql \
   	&& chown -R mysql:mysql /usr/local/mysql/ \
   	&& cd mysql && mkdir /etc/mysql && cp ./support-files/my-small.cnf /etc/mysql/my.cnf \
    	&& mkdir /etc/mysql/conf.d/ \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
# ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
	&& chmod 777 /var/run/mysqld \
# comment out a few problematic configuration values
	&& sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
	&& echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf \
	&& apt-get purge -y --auto-remove make cmake git wget libncurses5-dev bison advance-toolchain-at10.0-devel advance-toolchain-at10.0-perf advance-toolchain-at10.0-mcore-libs \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /server

VOLUME /var/lib/mysql
ENV PATH $PATH:/usr/local/mysql/bin:/usr/local/mysql/scripts
ENV LD_LIBRARY_PATH /usr/lib/powerpc64le-linux-gnu

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
RUN apt-get update \
	&& apt-get install libgnutls30 -y
EXPOSE 3306

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["mysqld"]

