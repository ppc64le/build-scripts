FROM node:10-slim

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH $PATH:$JAVA_HOME/bin
ENV GRADLE_OPTS: "-Dorg.gradle.daemon=false"
ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=en_US.UTF-8"

COPY connector_fix.patch /

RUN mkdir -p /usr/share/man/man1

RUN apt-get update -qq && apt-get install -qq bash sudo build-essential openjdk-8-jdk maven git vim python && \
    git clone https://github.com/xerial/sqlite-jdbc && cd sqlite-jdbc && git checkout 3.28.0 && \
    cd /sqlite-jdbc/src/main/resources/org/sqlite/native/Linux/ && mkdir ppc64le && \
    cp ppc64/libsqlitejdbc.so ppc64le/ && cd /sqlite-jdbc && \
    mvn package -DskipTests && cd / && \
    git clone https://github.com/industrial-data-space/trusted-connector && \
    cd trusted-connector && git checkout v2.0.0 && \
    git apply /connector_fix.patch && \
    ./gradlew clean build

CMD ["/bin/bash"]
