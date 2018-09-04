FROM openjdk:8

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"
ENV PATH=$PATH:$JAVA_HOME/bin
RUN apt-get update -y && \
    apt-get install -y build-essential g++ ant wget git && \
    wget http://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz && \
        tar -zxf apache-maven-3.3.3-bin.tar.gz && \
        cp -R apache-maven-3.3.3 /usr/local && \
        ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn && \
        git clone https://github.com/clir/clearnlp && cd clearnlp && \
        mvn -DskipTests package && \
        apt-get purge -y build-essential g++ ant wget git && \
        apt-get autoremove -y
WORKDIR clearnlp
CMD ["/bin/bash"]
