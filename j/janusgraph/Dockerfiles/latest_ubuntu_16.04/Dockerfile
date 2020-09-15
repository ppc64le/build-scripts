FROM ppc64le/ubuntu:16.04
MAINTAINER lysannef@us.ibm.com

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-ppc64el
ENV PATH $PATH:`pwd`/apache-maven-3.5.2/bin
RUN apt-get update && \
    apt-get install openjdk-8-jdk wget git maven -y && \
    git clone https://github.com/JanusGraph/janusgraph.git && \
    cd janusgraph && \
    mvn clean install -DskipTests=true && \
    apt-get purge -y openjdk-8-jdk wget git && apt-get autoremove -y

WORKDIR /janusgraph
