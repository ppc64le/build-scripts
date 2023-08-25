ARG alpine_version=3.18.2

# We copy files from the context into a scratch container first to avoid a problem where docker and
# docker-compose don't share layer hashes https://github.com/docker/compose/issues/883 normally.
# COPY --from= works around the issue.
FROM scratch as base1

COPY build-bin/alpine_build /apline-docker-bin/
COPY build-bin/docker/alpine_docker_build /apline-docker-bin/
COPY build-bin/docker/alpine_docker_args /apline-docker-bin/
COPY . /code/

FROM ppc64le/alpine:3.16.2 as docker-alpine

WORKDIR /code

COPY --from=base1 /code/ .

WORKDIR /install

ARG alpine_version
ENV ALPINE_VERSION=$alpine_version
RUN chmod +x /code/alpine_minirootfs
RUN /code/alpine_minirootfs $ALPINE_VERSION

FROM scratch as alpine
ARG maintainer="OpenZipkin https://gitter.im/openzipkin/zipkin"
LABEL maintainer=$maintainer
LABEL org.opencontainers.image.authors=$maintainer
ARG alpine_version
LABEL alpine-version=$alpine_version

COPY --from=docker-alpine /install /

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# RUN, COPY, and ADD instructions create layers. While layer count is less important in modern
# Docker, it doesn't help performance to intentionally make multiple RUN layers in a base image.
RUN \
  #
  # Java relies on /etc/nsswitch.conf. Put host files first or InetAddress.getLocalHost
  # will throw UnknownHostException as the local hostname isn't in DNS.
  echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
  #
  # Later installations may require more recent versions of packages such as nodejs
  for repository in main testing community; do \
  repository_url=https://dl-cdn.alpinelinux.org/alpine/edge/${repository} && \
  grep -qF -- ${repository_url} /etc/apk/repositories || echo ${repository_url} >> /etc/apk/repositories; \
  done && \
  #
  # Finalize install:
  # * java-cacerts: implicitly gets normal ca-certs used outside Java (this does not depend on java)
  # * libc6-compat: BoringSSL for Netty per https://github.com/grpc/grpc-java/blob/master/SECURITY.md#netty
  apk add --no-cache java-cacerts ca-certificates libc6-compat && \
  # Force install versions that don't have CVE-2023-2975. This can be removed on future versions.
  apk add --no-cache libcrypto3=3.1.1-r1 libssl3=3.1.1-r1 && \
  # Typically, only amd64 is tested in CI: Run a command to ensure binaries match current arch.
  ldd /lib/libz.so.1

ENTRYPOINT ["/bin/sh"]

#=================================================docker-java=================================================

ARG java_version=17.0.8_p7
FROM scratch as code

COPY build-bin/docker/install.sh /code/
COPY . /code/

FROM docker-alpine as base

ARG java_version
ARG java_home=/usr/lib/jvm/java-15-openjdk
LABEL java-version=$java_version
LABEL java-home=$java_home

ENV JAVA_VERSION=$java_version
ENV JAVA_HOME=$java_home
# Prefix Alpine Linux default path with ${JAVA_HOME}/bin
ENV PATH=${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /java

ENTRYPOINT ["java", "-jar"]

# The JDK image includes a few build utilities and Maven
FROM base as jdk
LABEL org.opencontainers.image.description="OpenJDK on Alpine Linux"
ARG java_version
ARG maven_version=3.8.8
LABEL maven-version=$maven_version

COPY --from=code /code/install.sh .
RUN chmod +x install.sh
RUN ./install.sh $java_version $maven_version && rm install.sh

# Use a temporary target to build a JRE using the JDK we just built
FROM jdk as install

WORKDIR /install

# Opt out of --strip-debug when openjdk15+arm64 per https://github.com/openzipkin/docker-java/issues/34
# This is because we cannot set the following in jlink -Djdk.lang.Process.launchMechanism=vfork
RUN if [ -d "/usr/lib/jvm/java-17-openjdk" ] && uname -m | grep -E 'aarch64|s390x'; then strip=""; else strip="--strip-debug"; fi && \
# Included modules cherry-picked from https://docs.oracle.com/en/java/javase/15/docs/api/
jlink --vm=server --no-header-files --no-man-pages --compress=0 ${strip} --add-modules \
java.base,java.logging,\
# java.desktop includes java.beans which is used by Spring
java.desktop,\
# our default server includes SQL
java.sql,\
# instrumentation
java.instrument,\
# remote debug
jdk.jdwp.agent,\
# JVM metrics such as garbage collection
jdk.management,\
# Prevents us from needing a different base layer for kafka-zookeeper
# non-Netty based DNS
java.naming,jdk.naming.dns,\
# TLS handehake with servers that use elliptic curve certificates
jdk.crypto.ec,\
# jdk.unsupported is undocumented but contains Unsafe, which is used by several dependencies to
# improve performance. Ex. sun.misc.Unsafe and friends
jdk.unsupported,\
# Elasticsearch 7+ crashes without Thai Segmentation support
#  Add <900K instead of a different base layer
jdk.localedata --include-locales en,th \
--output jre

# Our JRE image is minimal: Only Alpine, libc6-compat and a stripped down JRE
FROM base as jre
LABEL org.opencontainers.image.description="Minimal OpenJDK JRE on Alpine Linux"

COPY --from=install /install/jre/ ${JAVA_HOME}/

# Typically, only amd64 is tested in CI: Run a command to ensure binaries match current arch.
RUN java -version



#=================================================ubi=================================================


FROM registry.access.redhat.com/ubi8/ubi:8.7 as ubi
WORKDIR /code
RUN yum install -y java-11-openjdk-devel git wget && \
    export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)') && \
    export PATH=$JAVA_HOME/bin:$PATH && \
    java -version

RUN wget http://archive.apache.org/dist/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz && \
    tar -C /usr/local/ -xzvf apache-maven-3.8.8-bin.tar.gz && \
    mv /usr/local/apache-maven-3.8.8 /usr/local/maven && \
    export M2_HOME=/usr/local/maven && \
    export PATH=$PATH:$M2_HOME/bin  && \
    mvn -version && \
    git clone https://github.com/openzipkin/zipkin.git && \
    cd zipkin && \
    mvn clean install -DskipTests && \
    find . -name *jar*

#=================================================zipkin=================================================


ARG java_version=17.0.5_p8

# We copy files from the context into a scratch container first to avoid a problem where docker and
# docker-compose don't share layer hashes https://github.com/docker/compose/issues/883 normally.
# COPY --from= works around the issue.
FROM ubi as scratch

COPY build-bin/docker/docker-healthcheck /docker-bin/
COPY docker/start-zipkin /docker-bin/
COPY . /code/

FROM install as install2

WORKDIR /code

COPY --from=scratch /code/ .

WORKDIR /install

# When true, build-bin/maven/unjar searches /code for the artifact instead of resolving remotely.
# /code contains what is allowed in .dockerignore. On problem, ensure .dockerignore is correct.
ARG release_from_maven_build=false
ENV RELEASE_FROM_MAVEN_BUILD=$release_from_maven_build
ARG version=master
ENV VERSION=$version
ENV MAVEN_PROJECT_BASEDIR=/code

RUN mkdir zipkin && cd zipkin && \
    jar -xf /code/zipkin/zipkin-server/target/zipkin-server-*exec.jar && cd .. && \
    mkdir zipkin-slim && cd zipkin-slim && \
    jar -xf /code/zipkin/zipkin-server/target/zipkin-server-*slim.jar && cd .. 

# Almost everything is common between the slim and normal build
FROM jre as base-server

# All content including binaries and logs write under WORKDIR
ARG USER=zipkin
WORKDIR /${USER}

# Ensure the process doesn't run as root
RUN adduser -g '' -h ${PWD} -D ${USER}

# Add HEALTHCHECK and ENTRYPOINT scripts into the default search path
COPY --from=scratch /docker-bin/* /usr/local/bin/
# We use start period of 30s to avoid marking the container unhealthy on slow or contended CI hosts.
#
# If in production, you have a 30s startup, please report to https://gitter.im/openzipkin/zipkin
# including the values of the /health and /info endpoints as this would be unexpected.
HEALTHCHECK --interval=5s --start-period=30s --timeout=5s CMD ["docker-healthcheck"]

ENTRYPOINT ["start-zipkin"]

# Switch to the runtime user
USER ${USER}

FROM base-server as zipkin-slim
LABEL org.opencontainers.image.description="Zipkin slim distribution on OpenJDK and Alpine Linux"

COPY --from=install2 --chown=${USER} /install/zipkin-slim/ /zipkin/

EXPOSE 9411

FROM base-server as zipkin
LABEL org.opencontainers.image.description="Zipkin full distribution on OpenJDK and Alpine Linux"

# 3rd party modules like zipkin-aws will apply profile settings with this
ENV MODULE_OPTS=

COPY --from=install2 --chown=${USER} /install/zipkin/ /zipkin/

# Zipkin's full distribution includes Scribe support (albeit disabled)
EXPOSE 9410 9411