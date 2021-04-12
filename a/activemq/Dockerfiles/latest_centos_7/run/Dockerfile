FROM ppc64le/centos:7
MAINTAINER "Amir Sanjar <amir.sanjar@ibm.com>"

RUN cd && yum install java-1.8.0-openjdk-devel -y && \
    yum install -y git maven unzip && \
    git clone https://github.com/apache/activemq && \
    cd activemq && \
    mvn clean install -DskipTests=true && \
    cp assembly/target/apache-activemq-*-bin.zip /root/ && \
    cd /root && unzip apache-activemq-*-bin.zip && \
    rm -rf apache-activemq-*-SNAPSHOT-bin.zip /root/activemq && \
    chmod +x /root/apache-activemq-*-SNAPSHOT/bin/activemq 

ARG AMQ_VERSION
EXPOSE 8161
ENV PATH ${PATH}:/root/apache-activemq-${AMQ_VERSION}-SNAPSHOT/bin

CMD ["activemq", "console"]
