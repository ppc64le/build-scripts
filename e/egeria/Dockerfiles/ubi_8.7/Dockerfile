FROM registry.access.redhat.com/ubi8:8.7

ARG PACKAGE_VERSION=V4.0
ARG PACKAGE_NAME=egeria
ARG PACKAGE_URL=https://github.com/odpi/egeria.git

ENV SOURCE_DIR=/tmp/

RUN yum update -y && \
	yum install -y git wget tar java-17-openjdk-devel && \
	export JAVA_HOME=/usr/lib/jvm/java-17-openjdk && \
	export PATH=$JAVA_HOME/bin:$PATH && \
	cd ${SOURCE_DIR} && \
	git clone $PACKAGE_URL && \
	cd $PACKAGE_NAME && \
	git checkout $PACKAGE_VERSION && \
	./gradlew build -x test && \
	mkdir -p open-metadata-resources/open-metadata-deployment/docker/egeria/build/assembly && \
	cp -r open-metadata-distribution/open-metadata-assemblies/build/unpacked/egeria-${PACKAGE_VERSION:1}-distribution.tar.gz/* open-metadata-resources/open-metadata-deployment/docker/egeria/build/assembly

WORKDIR /opt/egeria

# Copy egeria distribution
RUN mkdir -p /deployments &&\
	cp -r ${SOURCE_DIR}/egeria/open-metadata-resources/open-metadata-deployment/docker/egeria/build/assembly/ /deployments &&\
	cp -r ${SOURCE_DIR}/egeria/open-metadata-resources/open-metadata-deployment/docker/egeria/build/assembly/truststore.p12 .

# Expose port 8080 (default) for client access, and allow for 5005 being used for remote java debug
EXPOSE 9443 5005

# By default, we run the server chassis
ENV JAVA_APP_JAR=server/server-chassis-spring-${PACKAGE_VERSION:-1}.jar

# This is used with regular class loader, ie any client code etc
# ENV JAVA_LIBDIR=/deployments/lib

# This is used when running a spring app such as the server chassis (default)
# Extend this accordingly via the environment, or within a new Dockerfile as needed
ENV LOADER_PATH=/deployments/server/lib

# Joloka will be removed shortly. For now disable to avoid errors
ENV AB_JOLOKIA_OFF=true

# See issue 3740 - we leave the metaspace size as unlimited - jvm default
ENV JAVA_OPTS_APPEND="-XX:MaxMetaspaceSize=1g"
