FROM openjdk:8

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
        apt-get install -y git wget && \
        wget https://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz && \
        tar -zxf apache-maven-3.3.3-bin.tar.gz && \
        cp -R apache-maven-3.3.3 /usr/local && \
        ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn && \
        git clone https://github.com/bartdag/py4j.git && \
        cd py4j/py4j-java && \
        mvn install && \
        apt-get purge -y git wget && apt-get autoremove -y
ENV PATH=$PATH:$JAVA_HOME/bin

WORKDIR py4j/py4j-java
CMD ["/bin/bash"]
