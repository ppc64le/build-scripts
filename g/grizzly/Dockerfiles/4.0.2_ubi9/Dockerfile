FROM registry.access.redhat.com/ubi9/ubi:9.3

ARG PACKAGE_VERSION=4.0.2-RELEASE

RUN yum install -y java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless git make wget gcc-c++ && \
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk && \
    export PATH=$PATH:$JAVA_HOME/bin

RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz && \
    tar -zxf apache-maven-3.8.7-bin.tar.gz && \
    cp -R apache-maven-3.8.7 /usr/local && \
    ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

RUN git clone https://github.com/eclipse-ee4j/grizzly && \
    cd grizzly/ && \
    git checkout $PACKAGE_VERSION && \
    mvn clean install -DskipTests

EXPOSE 8080
CMD ["/bin/bash"]

