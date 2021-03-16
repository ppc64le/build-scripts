############################################################
# Dockerfile to run an Apache Cassandra Container
############################################################

FROM registry.access.redhat.com/ubi8/ubi:latest

ARG VERSION=3.11.x

###Required Labels
LABEL name="cassandra" \
      maintainer="amits2@us.ibm.com" \
      vendor="cassandra" \
      version=$VERSION \
      release="1" \
      summary="Red Hat UBI cassandra" \
      description="Red Hat UBI cassandra Application"

RUN groupadd cassandra && useradd -r -g cassandra cassandra -m -d /home/cassandra/

#Install dependencies
RUN yum update -y \
    && yum -y install java-1.8.0-openjdk python2 procps sudo \
	&& echo "JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")" | sudo tee -a /etc/profile \
    && source /etc/profile

#Install the latest stable release of Apache Cassandra 3.11.x	
RUN echo $'[cassandra]\n\
name=Apache Cassandra\n\
baseurl=https://www.apache.org/dist/cassandra/redhat/311x/\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://www.apache.org/dist/cassandra/KEYS\n'\
>> /etc/yum.repos.d/cassandra311x.repo
	
RUN yum update -y \
    && yum -y install cassandra 

ENV CASSANDRA_CONFIG /etc/cassandra/conf/

RUN set -eux; \
	\
# https://issues.apache.org/jira/browse/CASSANDRA-13345
# "The stack size specified is too small, Specify at least 328k"
		if grep -q -- '^-Xss' "$CASSANDRA_CONFIG/jvm.options"; then \
# 3.11+ (jvm.options)
			grep -- '^-Xss256k$' "$CASSANDRA_CONFIG/jvm.options"; \
			sed -ri 's/^-Xss256k$/-Xss512k/' "$CASSANDRA_CONFIG/jvm.options"; \
			grep -- '^-Xss512k$' "$CASSANDRA_CONFIG/jvm.options"; \
		fi;

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service

RUN mkdir /licenses
COPY licensing.txt /licenses

USER cassandra
WORKDIR /home/cassandra

EXPOSE 7000 7001 7199 9042 9160

CMD ["cassandra", "-R", "-f"]
