############################################################
# Dockerfile to run an Apache Cassandra Container
############################################################

FROM registry.access.redhat.com/ubi8/ubi:latest

ARG VERSION=4.1.3

###Required Labels
LABEL name="cassandra" \
      maintainer="Pratik.Tonage@ibm.com" \
      vendor="cassandra" \
      version=$VERSION \
      release="1" \
      summary="Red Hat UBI cassandra" \
      description="Red Hat UBI cassandra Application"

RUN groupadd cassandra && useradd -r -g cassandra cassandra -m -d /home/cassandra/

#Install dependencies
RUN yum update -y \
    && yum -y install java-1.8.0-openjdk python3 procps sudo \
	&& echo "JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")" | sudo tee -a /etc/profile \
    && source /etc/profile

#Install the latest stable release of Apache Cassandra 4.1.3
RUN echo $'[cassandra]\n\
name=Apache Cassandra\n\
baseurl=https://redhat.cassandra.apache.org/41x/\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://downloads.apache.org/cassandra/KEYS\n'\
>> /etc/yum.repos.d/cassandra41x.repo
	
RUN yum update -y \
    && yum -y install cassandra 

ENV CASSANDRA_CONFIG /etc/cassandra/conf/

RUN set -eux; \
	\
# https://issues.apache.org/jira/browse/CASSANDRA-13345
# "The stack size specified is too small, Specify at least 328k"
		if grep -q -- '^-Xss' "$CASSANDRA_CONFIG/jvm-server.options"; then \
# 3.11+ (jvm-server.options)
			grep -- '^-Xss256k$' "$CASSANDRA_CONFIG/jvm-server.options"; \
			sed -ri 's/^-Xss256k$/-Xss512k/' "$CASSANDRA_CONFIG/jvm-server.options"; \
			grep -- '^-Xss512k$' "$CASSANDRA_CONFIG/jvm-server.options"; \
		fi;

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service

RUN mkdir /licenses
COPY licensing.txt /licenses

# Native library for Netty needs to be build on Power
RUN yum install -y git maven make autoconf automake libtool gcc-c++ \
    && git clone https://github.com/netty/netty.git && cd netty \
	&& VER=$(find /usr/share/cassandra -name netty-all*.jar | xargs basename | sed "s/netty-all/netty/" | sed "s/\.jar//") \
	&& git checkout $VER \
	&& cd transport-native-unix-common  && mvn clean install -DskipTests && cd .. \
	&& cd transport-native-epoll && mvn clean install -DskipTests && cd .. \
	&& cd all && mvn clean install -DskipTests &&  cp -f target/netty-all*.jar /usr/share/cassandra \
	&& yum remove -y autoconf automake libtool git \
	&& cd ../.. && rm -rf netty

USER cassandra
WORKDIR /home/cassandra

EXPOSE 7000 7001 7199 9042 9160

CMD ["cassandra", "-R", "-f"]
