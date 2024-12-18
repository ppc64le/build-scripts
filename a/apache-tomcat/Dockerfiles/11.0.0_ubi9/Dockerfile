FROM registry.access.redhat.com/ubi9/ubi:9.3 as build-tomcat

WORKDIR /tmp

ARG PACKAGE_VERSION=11.0.0-M26

RUN yum install -y git wget gcc-c++ gcc java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless unzip && \
    export JAVA_HOME=/usr/lib/jvm/java-21-openjdk && \
    export PATH=$PATH:$JAVA_HOME/bin && \
    wget -c https://mirrors.advancedhosters.com/apache/ant/binaries/apache-ant-1.10.14-bin.zip && \
    unzip apache-ant-*.zip && \
    mv apache-ant-*/ /usr/local/ant && \
    export ANT_HOME="/usr/local/ant" && \
    export PATH="$PATH:/usr/local/ant/bin" && \
    git clone https://github.com/apache/tomcat.git && \
    cd tomcat && \
    git checkout $PACKAGE_VERSION && \
    ant

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

RUN microdnf install -y java-17-openjdk java-17-openjdk-devel

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk
ENV PATH=$PATH:$JAVA_HOME/bin

RUN mkdir -p /usr/local/tomcat

COPY --from=build-tomcat /tmp/tomcat/output/build /usr/local/tomcat/

EXPOSE 8080

WORKDIR /usr/local/tomcat

ENTRYPOINT ["/usr/local/tomcat/bin/catalina.sh", "run"]
