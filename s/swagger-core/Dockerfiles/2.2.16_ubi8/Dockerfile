FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=v2.2.16

RUN yum install -y git wget gcc gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless tzdata-java && \
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk && \
    export PATH=$PATH:$JAVA_HOME/bin

RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz && \
    tar -zxf apache-maven-3.8.7-bin.tar.gz && \
    cp -R apache-maven-3.8.7 /usr/local && \
    ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn


RUN git clone https://github.com/swagger-api/swagger-core && \
    cd swagger-core/ && \
    git checkout $PACKAGE_VERSION && \
    ./mvnw clean install

CMD ["/bin/bash"]
