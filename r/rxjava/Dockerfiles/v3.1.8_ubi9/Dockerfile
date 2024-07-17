FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vipul Ajmera <Vipul.Ajmera@ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV JRE_HOME=${JAVA_HOME}/jre
ENV PATH=$PATH:${JAVA_HOME}/bin

ARG PACKAGE_VERSION=${1:-v3.1.8}

RUN yum install -y java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless git wget unzip && \
    git clone https://github.com/ReactiveX/RxJava.git && \
    cd RxJava && \
    git checkout $PACKAGE_VERSION && \
    ./gradlew build

CMD ["/bin/bash"]
