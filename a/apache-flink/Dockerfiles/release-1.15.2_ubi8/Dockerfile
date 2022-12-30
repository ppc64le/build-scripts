FROM registry.access.redhat.com/ubi8/ubi:latest

ARG PACKAGE_VERSION="release-1.15.2"
ARG MAVEN_VERSION=3.6.3
ARG PACKAGE_URL=https://github.com/apache/flink.git
ENV GOSU_VERSION=1.11
ENV DISABLE_JEMALLOC=true

RUN gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
	curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.11/gosu-ppc64el" && \
	curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.11/gosu-ppc64el.asc" && \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
	command -v gpgconf && gpgconf --kill all || : && \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc && \
	chmod +x /usr/local/bin/gosu && \
	gosu nobody true
	
RUN curl -L https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst-`uname -s`-`uname -m` -o envsubst && \
	chmod +x envsubst && \
	mv envsubst /usr/local/bin

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
ENV FLINK_HOME /flink/build-target
ENV PATH=$FLINK_HOME/bin:$PATH

RUN groupadd --system --gid=9999 flink && \
    useradd --system --home-dir $FLINK_HOME --uid=9999 --gid=flink flink

ENV FLINK_HOME /flink/build-target
ENV PATH=$FLINK_HOME/bin:$PATH

WORKDIR $FLINK_HOME

EXPOSE 6123 8081
CMD ["help"]