FROM ppc64le/ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update -y && \
    apt-get install -y git wget maven openjdk-8-jdk openjdk-8-jre && \
    git clone https://github.com/FasterXML/jackson-parent && \
    cd jackson-parent && \
    wget https://repo.maven.apache.org/maven2/org/apache/felix/maven-bundle-plugin/3.0.1/maven-bundle-plugin-3.0.1.jar && \
    mkdir -p $HOME/.m2/repository/org/apache/felix/maven-bundle-plugin/3.0.1 && \
    mv maven-bundle-plugin-3.0.1.jar $HOME/.m2/repository/org/apache/felix/maven-bundle-plugin/3.0.1 && \
    git clone https://github.com/FasterXML/jackson-module-jsonSchema && \
    cd jackson-module-jsonSchema && \
    mvn install && \
    cd .. && \
    mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V && \
    mvn test -B && \
    apt-get remove --purge -y git wget maven

CMD ["/bin/bash"]
