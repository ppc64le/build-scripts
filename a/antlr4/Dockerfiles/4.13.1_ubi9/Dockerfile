FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Mohit Pawar <mohit.pawar@ibm.com>"

ARG PACKAGE_VERSION="4.13.1"
ARG MAVEN_OPTS="-Xmx1G"

RUN yum install -y git wget

#installing java-17
RUN yum install -y tzdata java-17-openjdk.ppc64le java-17-openjdk-devel.ppc64le git wget \
    && export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)') \
    && export PATH=$JAVA_HOME/bin:$PATH

#installing maven 3.8.7
RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz && \
    tar -zxf apache-maven-3.8.7-bin.tar.gz && \
    cp -R apache-maven-3.8.7 /usr/local && \
    ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

RUN git clone https://github.com/antlr/antlr4.git \
    && cd antlr4 \
    && git checkout $PACKAGE_VERSION \
    && mvn clean \
    && mvn -DskipTests install \
    && cd runtime-testsuite \
    && mvn -Dtest=java.** test

ARG user=appuser
ARG group=appuser
ARG uid=1000
ARG gid=1000

RUN adduser \
    --comment "" \
    --home-dir "$(pwd)" \
    --no-create-home \
    --uid "${uid}" \
    "${user}"

WORKDIR /work
ENTRYPOINT ["java", "-Xmx500M", "-cp", "/usr/local/lib/antlr4-tool.jar", "org.antlr.v4.Tool"]
