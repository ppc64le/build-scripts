FROM ubuntu:16.04
MAINTAINER Vibhuti.Sawant@ibm.com

USER root

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update && apt-get install -y git gcc g++ make cmake bison build-essential \
        libncurses5-dev wget gzip tar python ant unzip libghc-zlib-dev zlibc less \
        openjdk-8-jdk openjdk-8-jre automake autoconf mysql-server \
        libsnappy-dev libsnappy-java libsnappy-jni openssl maven libprotobuf-dev protobuf-c-compiler \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV JAVE_HOME /usr/lib/jvm/java-11-openjdk-ppc64el
ENV JAVA_OPTS "-Xmx1024m -XX:MaxPermSize=256m"
ENV JAVA_OPTS "-Xmx2048M -Xss512M -XX:MaxPermSize=2048M -XX:+CMSClassUnloadingEnabled -XX:+UseConcMarkSweepGC"
ENV MAVEN_HOME "/usr/share/maven"
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH
ENV LD_LIBRARY_PATH /usr/local/lib
ENV PRESTO_HOME /presto
ENV PRESTO_USER presto
ENV PRESTO_CONF_DIR ${PRESTO_HOME}/etc
ENV PATH $PATH:$PRESTO_HOME/bin

RUN useradd \
                --create-home \
                --home-dir ${PRESTO_HOME} \
				--shell /bin/bash \
                $PRESTO_USER

RUN mkdir -p $PRESTO_HOME && \
    cd /tmp/ && git clone https://github.com/prestodb/presto.git && \
    cd presto && git checkout 0.209 && \
    sed -i 's/<module>presto-docs<\/module>/<!-- module>presto-docs<\/module -->/g' pom.xml && \
    mvn clean install -DskipTests

RUN mv /tmp/presto/presto-server/target/presto-server-0.209/* $PRESTO_HOME && \
    mkdir -p ${PRESTO_HOME}/data && \
    cd ${PRESTO_HOME}/bin && \
    mv /tmp/presto/presto-cli/target/presto-cli-0.209-executable.jar . && \
    mv presto-cli-0.209-executable.jar presto && \
    chmod +x presto && \
    chown -R ${PRESTO_USER}:${PRESTO_USER} $PRESTO_HOME

# Need to work with python2
# See: https://github.com/prestodb/presto/issues/4678
ENV PYTHON2_DEBIAN_VERSION 2.7.13-2
RUN apt-get update && apt-get install -y --no-install-recommends \
                python \
    && rm -rf /var/lib/apt/lists/* \
    && cd /usr/local/bin \
    && rm -rf idle pydoc python python-config
RUN mkdir -p ${PRESTO_CONF_DIR}/ && cp -a /tmp/presto/presto-product-tests/conf/presto/etc/*  ${PRESTO_CONF_DIR}/
USER $PRESTO_USER

CMD ["launcher", "run"]

