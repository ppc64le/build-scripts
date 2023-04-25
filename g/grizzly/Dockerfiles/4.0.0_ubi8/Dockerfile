FROM registry.access.redhat.com/ubi8/ubi:8.7

RUN yum install -y git make wget gcc-c++ java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless && \
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk && \
    export PATH=$PATH:$JAVA_HOME/bin

RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz && \
    tar -zxf apache-maven-3.8.7-bin.tar.gz && \
    cp -R apache-maven-3.8.7 /usr/local && \
    ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

RUN git clone https://github.com/eclipse-ee4j/grizzly && \
    cd grizzly/ && \
    git checkout 4.0.0 && \
    mvn clean install -DskipTests

ENV CLASSPATH /grizzly/modules/grizzly/target/grizzly-framework-4.0.1-SNAPSHOT.jar
EXPOSE 8080
CMD ["/bin/bash"]
