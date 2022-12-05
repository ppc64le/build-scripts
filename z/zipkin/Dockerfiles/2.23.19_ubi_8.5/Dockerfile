
FROM registry.access.redhat.com/ubi8/ubi:8.5 

LABEL MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_URL=https://github.com/openzipkin/zipkin
ARG PACKAGE_NAME=zipkin
ARG PACKAGE_VERSION=2.23.19

WORKDIR /opt

RUN yum update -y && \
    yum install -y java-11-openjdk-devel git maven && \
    git clone $PACKAGE_URL && \
    cd $PACKAGE_NAME/$PACKAGE_NAME && \
    git checkout $PACKAGE_VERSION && \
    mvn install -Dmaven.test.skip=true 
    



