FROM registry.access.redhat.com/ubi8/ubi:latest

ARG PACKAGE_VERSION="release-1.15.2"
ARG MAVEN_VERSION=3.6.3
ARG PACKAGE_URL=https://github.com/apache/flink.git

RUN yum install -y sudo && \
	sudo yum update -y && \
	sudo yum install -y git wget java-1.8.0-openjdk-devel xz && \
	export JAVA_HOME=export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

RUN sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm &&\
	sudo yum install -y postgresql10-libs && \
	sudo yum install -y postgresql10 postgresql10-server postgresql10-contrib
	
RUN wget https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz && \
	tar xzf apache-maven-3.6.3-bin.tar.gz && \
	export M2_HOME=`pwd`/apache-maven-${MAVEN_VERSION} && \
	export PATH=`pwd`/apache-maven-${MAVEN_VERSION}/bin:${PATH} && \
	git clone $PACKAGE_URL && \
	cd flink && \
	git checkout $PACKAGE_VERSION && \
	mvn clean package -DskipTests -Pskip-webui-build