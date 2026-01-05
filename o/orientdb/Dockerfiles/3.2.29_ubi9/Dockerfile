FROM registry.access.redhat.com/ubi9:9.3

#Install IBM Semeru Runtime Java 11
RUN yum install -y git wget tar openssl-devel freetype fontconfig && \
    wget https://github.com/ibmruntimes/semeru11-certified-binaries/releases/download/jdk-11.0.18%2B10_openj9-0.36.1/ibm-semeru-certified-jdk_ppc64le_linux_11.0.18.0.tar.gz && \
    tar -C /usr/local -zxf ibm-semeru-certified-jdk_ppc64le_linux_11.0.18.0.tar.gz && \
    export JAVA_HOME=/usr/local/jdk-11.0.18+10 && \
    export JAVA11_HOME=/usr/local/jdk-11.0.18+10 && \
    export PATH=$PATH:/usr/local/jdk-11.0.18+10/bin && \
    ln -sf /usr/local/jdk-11.0.18+10/bin/java /usr/bin && \
    rm -f ibm-semeru-certified-jdk_ppc64le_linux_11.0.18.0.tar.gz

ENV ORIENTDB_DOWNLOAD_SERVER=https://repo1.maven.org/maven2/com/orientechnologies
ENV PACKAGE_VERSION=3.2.29
ENV ORIENTDB_DOWNLOAD_MD5=f21cac84ee38ba4009e22162e2ce38d3
ENV ORIENTDB_DOWNLOAD_SHA1=1bcbd48ed00551cb9cd37e43fede5fe656f1f96f

ENV ORIENTDB_DOWNLOAD_URL=${ORIENTDB_DOWNLOAD_SERVER}/orientdb-community/$PACKAGE_VERSION/orientdb-community-$PACKAGE_VERSION.tar.gz

#download distribution tar, untar and delete databases
RUN mkdir /orientdb \
  && wget $ORIENTDB_DOWNLOAD_URL \
  && echo "$ORIENTDB_DOWNLOAD_MD5 *orientdb-community-$PACKAGE_VERSION.tar.gz" | md5sum -c - \
  && echo "$ORIENTDB_DOWNLOAD_SHA1 *orientdb-community-$PACKAGE_VERSION.tar.gz" | sha1sum -c - \
  && tar -xvzf orientdb-community-$PACKAGE_VERSION.tar.gz -C /orientdb --strip-components=1 \
  && rm orientdb-community-$PACKAGE_VERSION.tar.gz \
  && rm -rf /orientdb/databases/*

ENV PATH=/orientdb/bin:$PATH

VOLUME ["/orientdb/backup", "/orientdb/databases", "/orientdb/config"]

WORKDIR /orientdb

#OrientDb binary
EXPOSE 2424

#OrientDb http
EXPOSE 2480

# Default command start the server
CMD ["server.sh"]
