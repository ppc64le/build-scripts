FROM registry.access.redhat.com/ubi9:9.3

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=2.5.1
ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum install -y wget git

RUN dnf install -y git make gcc gcc-c++ java-11-openjdk-devel libtool file diffutils bc wget

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH


RUN wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz && \
    tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz && \
    rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz && \
    mv /usr/local/apache-maven-3.8.6 /usr/local/maven

ENV M2_HOME=/usr/local/maven
ENV PATH=$PATH:$M2_HOME/bin
ENV PATH=$PATH:/usr/local/bin/

RUN cd $SOURCE_DIR && \
    git clone https://github.com/netplex/json-smart-v2 && \
    cd json-smart-v2/json-smart && \
    git checkout $PACKAGE_VERSION && \
    mvn clean install -DskipTests

CMD ["bash"]
