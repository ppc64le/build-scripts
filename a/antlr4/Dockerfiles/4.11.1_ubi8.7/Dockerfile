FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Mohit Pawar <mohit.pawar@ibm.com>"

ARG PACKAGE_VERSION="v4.11.1"
ARG MAVEN_OPTS="-Xmx1G"

RUN yum install -y git wget

#installing java-17
RUN yum install -y tzdata java-17-openjdk.ppc64le java-17-openjdk-devel.ppc64le git wget \
    && export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)') \
    && export PATH=$JAVA_HOME/bin:$PATH

#installing maven 3.8.7
RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz && \
    tar -zxf apache-maven-3.8.6-bin.tar.gz && \
    cp -R apache-maven-3.8.6 /usr/local && \
    ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn

RUN git clone https://github.com/antlr/antlr4.git \
    && cd antlr4 \
    && git checkout $PACKAGE_VERSION \
    && mvn -DskipTests install 

CMD ["/bin/bash"]
