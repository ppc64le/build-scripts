FROM ppc64le/openjdk:8

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN groupadd -r cassandra --gid=999 && useradd -r -g cassandra --uid=999 cassandra

RUN echo "deb [arch=amd64] http://www.apache.org/dist/cassandra/debian 311x main" | tee -a /etc/apt/sources.list.d/cassandra.sources.list && \
	curl https://www.apache.org/dist/cassandra/KEYS | apt-key add - && \
	apt-get update -y && \
	apt-get -y install cassandra && \
	sed -i -e s/Xss256/Xss512/g /etc/cassandra/jvm.options

USER cassandra

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 7000 7001 7199 9042 9160

CMD ["/usr/sbin/cassandra", "-f"]
