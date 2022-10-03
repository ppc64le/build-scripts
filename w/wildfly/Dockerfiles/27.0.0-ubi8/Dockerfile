
FROM registry.access.redhat.com/ubi8/ubi:8.4


ARG PACKAGE_VERSION=${1:-24.0.0.Final}

RUN yum update -y && \
    yum install -y git wget sudo tar java-11-openjdk-devel && \
    wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz && \
    tar -zxf apache-maven-3.6.3-bin.tar.gz && \
    cp -R apache-maven-3.6.3 /usr/local && \
    ln -s /usr/local/apache-maven-3.6.3/bin/mvn /usr/bin/mvn && \
    git clone https://github.com/wildfly/wildfly && \
    cd wildfly && \
    git checkout $PACKAGE_VERSION && \
    mvn install -DskipTests

ENV PATH=$PATH:$JAVA_HOME/bin

CMD ["/bin/bash"]

