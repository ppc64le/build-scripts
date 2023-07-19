FROM registry.access.redhat.com/ubi8/ubi:latest 

ARG PACKAGE_VERSION=rel/nifi-1.22.0

ENV NIFI_BASE_DIR=/opt/nifi
ENV NIFI_HOME ${NIFI_BASE_DIR}/nifi-current

#Install dependecies
RUN yum install -y wget git java-17-openjdk-devel

# Install maven.
RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz && \
    tar -xvzf apache-maven-3.8.6-bin.tar.gz && \
    cp -R apache-maven-3.8.6 /usr/local && \
    ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn

#Build and test the package
RUN git clone https://github.com/apache/nifi.git && \
    cd nifi && git checkout ${PACKAGE_VERSION} && \
    sed -i '/<artifactId>snappy-java<\/artifactId>/!b;n;c\\t\t<version>1.1.8</version>' pom.xml && \
    find="<additionalJOption>\-J\-Xmx512m<\/additionalJOption>" && \
    replace="<additionalJOptions>\
    <additionalJOption>\-J\-Xmx3g</additionalJOption>\
    <additionalJOption>\-J\-XX:+UseG1GC<\/additionalJOption>\
    <additionalJOption>\-J\-XX:ReservedCodeCacheSize=1g<\/additionalJOption>\
    <\/additionalJOptions>" && \
    sed -i "s#$find#$replace#g" pom.xml && \
    mvn install -Dmaven.test.skip=true

EXPOSE 8080 8443 10000 8000

WORKDIR /nifi

ENTRYPOINT ["/nifi/nifi-docker/dockerhub/sh/start.sh"]
