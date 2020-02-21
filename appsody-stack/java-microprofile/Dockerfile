# Step 1: Build the user's application
#FROM adoptopenjdk/openjdk8-openj9 as compile
FROM adoptopenjdk/openjdk8-openj9-ubi as compile

ARG MAVEN_VERSION=3.6.3
ARG USER_HOME_DIR="/root"
ARG SHA=c35a1803a6e70a126e80b2b3ae33eed961f83ed74d18fcd16909b2d44d7dada3203f1ffe726c17ef8dcca2dcaa9fca676987befeadc9b9f759967a8cb77181c0
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN yum -y update && yum install -y curl \
  && mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

RUN  yum -y clean all && yum repolist \
  && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && yum -y install unzip wget xmlstarlet

# Copy and build the dev.appsody:java-microprofile parent pom
COPY ./pom.xml /project/pom.xml
RUN cd /project && mvn -B install dependency:go-offline -DskipTests

# Copy and run a simple version check
COPY ./util /project/util
RUN  /project/util/check_version build

# Copy the user's application pom and resolve all dependencies
COPY ./user-app/pom.xml /project/user-app/pom.xml
RUN cd /project/user-app && mvn package -Dskip=true -DskipTests

# Download Open Liberty here to prevent redownloading each time the app is changed
RUN cd /project/user-app && mvn -B liberty:install-server

# Copy and build the application source. 
# Remove quick-start-security.xml since it is only needed during local development.
COPY ./user-app/src /project/user-app/src
RUN cd /project/user-app && \
    rm -f src/main/liberty/config/configDropins/defaults/quick-start-security.xml && \
    mvn package -DskipTests

RUN cd /project/user-app/target && \
    unzip *.zip && \
    mkdir /config && \
    mv wlp/usr/servers/*/* /config/

# Step 2: Package Open Liberty image
FROM open-liberty:{{.stack.libertyversion}}-kernel-java8-openj9-ubi

COPY --chown=1001:0 --from=compile /config/ /config/

RUN configure.sh
