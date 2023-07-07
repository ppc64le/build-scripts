FROM ibmcom/docker-ppc64le:18.06.3_ubi7

###Required Labels
LABEL name="zookeeper" \
      maintainer="sethp@us.ibm.com" \
      vendor="zookeeper" \
      version="3.4.14" \
      release="1" \
      summary="Red Hat UBI zookeeper" \
      description="Red Hat UBI zookeeper Application"

RUN groupadd zookeeper && useradd -r -g zookeeper zookeeper -m -d /home/zookeeper/

ARG ZOOKEEPER_VERSION 3.4.14

#Download Zookeeper
RUN yum install -y net-tools && wget -q http://mirror.vorboss.net/apache/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz && \
wget -q https://www.apache.org/dist/zookeeper/KEYS && \
wget -q https://www.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc

#Verify download
RUN gpg --import KEYS && \
gpg --verify zookeeper-${ZOOKEEPER_VERSION}.tar.gz.asc

#Install
RUN tar -xzf zookeeper-${ZOOKEEPER_VERSION}.tar.gz -C /opt

#Configure
RUN mv /opt/zookeeper-${ZOOKEEPER_VERSION}/conf/zoo_sample.cfg /opt/zookeeper-${ZOOKEEPER_VERSION}/conf/zoo.cfg \
    && mkdir /licenses && cp /opt/zookeeper-${ZOOKEEPER_VERSION}/LICENSE.txt /licenses/licensing.txt 

ENV ZK_HOME /opt/zookeeper-${ZOOKEEPER_VERSION}
RUN sed  -i "s|/tmp/zookeeper|$ZK_HOME/data|g" $ZK_HOME/conf/zoo.cfg; mkdir $ZK_HOME/data \
    && chmod -R 777 /opt/zookeeper-${ZOOKEEPER_VERSION}/

ADD start-zk.sh /usr/bin/start-zk.sh 
EXPOSE 2181 2888 3888

WORKDIR /opt/zookeeper-${ZOOKEEPER_VERSION}
VOLUME ["/opt/zookeeper-${ZOOKEEPER_VERSION}/conf", "/opt/zookeeper-${ZOOKEEPER_VERSION}/data"]

USER zookeeper
CMD  bash /usr/bin/start-zk.sh
