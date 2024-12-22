FROM registry.access.redhat.com/ubi9/ubi:9.3

ARG PACKAGE_VERSION=rel/nifi-2.0.0-M4

ENV NIFI_BASE_DIR=/opt/nifi
ENV NIFI_HOME=${NIFI_BASE_DIR}/nifi-current

#Install dependecies
RUN yum install -y java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless git wget gcc gcc-c++ && \
    export JAVA_HOME=/usr/lib/jvm/java-21-openjdk && \
    export PATH=$PATH:$JAVA_HOME/bin

# Install maven.
RUN wget https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz && \
    tar -xvzf apache-maven-3.9.6-bin.tar.gz && \
    cp -R apache-maven-3.9.6 /usr/local && \
    ln -s /usr/local/apache-maven-3.9.6/bin/mvn /usr/bin/mvn

#Build and test the package
RUN git clone https://github.com/apache/nifi.git && \
    cd nifi && git checkout ${PACKAGE_VERSION} && \
    ./mvnw -V -nsu -ntp -ff install -D skipTests -am -pl :nifi-python-framework -pl :nifi-python-extension-api -pl :nifi-python-test-extensions -pl nifi-system-tests/nifi-system-test-suite -pl nifi-system-tests/nifi-stateless-system-test-suite -pl -:nifi-frontend

EXPOSE 8080 8443 10000 8000

WORKDIR /nifi

ENTRYPOINT ["/nifi/nifi-docker/dockerhub/sh/start.sh"]