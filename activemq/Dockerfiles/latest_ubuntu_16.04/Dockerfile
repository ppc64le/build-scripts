FROM openjdk:8-jdk
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN cd && apt-get update -y && \
    apt-get install -y git maven doxygen && \
    git clone https://github.com/apache/activemq && \
    cd activemq && \
    mvn clean install -DskipTests=true && \
    apt-get remove --purge -y git maven doxygen && \
    apt-get autoremove -y && \
    cp assembly/target/apache-activemq-5.16.0-SNAPSHOT-bin.zip /root/ && \
    cd /root && unzip apache-activemq-5.16.0-SNAPSHOT-bin.zip && \
    rm -rf apache-activemq-5.16.0-SNAPSHOT-bin.zip /root/activemq && \
    chmod +x /root/apache-activemq-5.16.0-SNAPSHOT/bin/activemq 

EXPOSE 8161
ENV PATH $PATH:/root/apache-activemq-5.16.0-SNAPSHOT/bin
CMD ["activemq", "console"]
