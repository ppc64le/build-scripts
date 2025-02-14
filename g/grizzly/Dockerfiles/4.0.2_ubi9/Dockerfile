FROM registry.access.redhat.com/ubi9/ubi:9.3

ARG PACKAGE_VERSION=4.0.2-RELEASE

RUN yum install -y git make wget gcc-c++ && \
    wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.22%2B7/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.22_7.tar.gz && \
    tar -C /usr/local -xzf OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.22_7.tar.gz && \
    export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8" && \
    export JAVA_HOME=/usr/local/jdk-11.0.22+7/ && \
    export PATH=$PATH:/usr/local/jdk-11.0.22+7/bin && \
    ln -sf /usr/local/jdk-11.0.22+7/bin/java /usr/bin/ && \
    rm -rf OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.22_7.tar.gz

RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz && \
    tar -zxf apache-maven-3.8.8-bin.tar.gz && \
    cp -R apache-maven-3.8.8 /usr/local && \
    ln -s /usr/local/apache-maven-3.8.8/bin/mvn /usr/bin/mvn

RUN git clone https://github.com/eclipse-ee4j/grizzly && \
    cd grizzly/ && \
    git checkout $PACKAGE_VERSION && \
    mvn --show-version  --no-transfer-progress --activate-profiles staging  --define skipTests=true install

EXPOSE 8080
CMD ["/bin/bash"]

