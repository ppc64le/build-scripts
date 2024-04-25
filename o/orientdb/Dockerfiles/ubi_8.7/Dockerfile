FROM registry.access.redhat.com/ubi8:8.7

#Install IBM Semeru Runtime Java 11
RUN yum update -y \
    && yum -y install openssl wget ca-certificates freetype fontconfig \
    && wget https://github.com/ibmruntimes/semeru11-certified-binaries/releases/download/jdk-11.0.18%2B10_openj9-0.36.1/ibm-semeru-certified-jdk_ppc64le_linux_11.0.18.0.tar.gz \
    && tar -zxf ibm-semeru-certified-jdk_ppc64le_linux_11.0.18.0.tar.gz \
    && rm -rf ibm-semeru-certified-jdk_ppc64le_linux_11.0.18.0.tar.gz

ENV JAVA_HOME=$PWD/jdk-11.0.18+10
ENV PATH=$JAVA_HOME/bin:$PATH
ENV IBM_JAVA_OPTIONS="-XX:+UseContainerSupport"

ENV ORIENTDB_DOWNLOAD_SERVER=https://repo1.maven.org/maven2/com/orientechnologies
ENV ORIENTDB_VERSION=3.2.20
ENV ORIENTDB_DOWNLOAD_MD5=5b6d0296d7c43cdcf22fbc07d00782f4
ENV ORIENTDB_DOWNLOAD_SHA1=c5b1823272532d911c93ce68be4dfcf60c27ab72

ENV ORIENTDB_DOWNLOAD_URL=${ORIENTDB_DOWNLOAD_SERVER}/orientdb-community/$ORIENTDB_VERSION/orientdb-community-$ORIENTDB_VERSION.tar.gz

#download distribution tar, untar and delete databases
RUN mkdir /orientdb \
  && wget $ORIENTDB_DOWNLOAD_URL \
  && echo "$ORIENTDB_DOWNLOAD_MD5 *orientdb-community-$ORIENTDB_VERSION.tar.gz" | md5sum -c - \
  && echo "$ORIENTDB_DOWNLOAD_SHA1 *orientdb-community-$ORIENTDB_VERSION.tar.gz" | sha1sum -c - \
  && tar -xvzf orientdb-community-$ORIENTDB_VERSION.tar.gz -C /orientdb --strip-components=1 \
  && rm orientdb-community-$ORIENTDB_VERSION.tar.gz \
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