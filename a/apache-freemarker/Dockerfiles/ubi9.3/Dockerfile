FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vipul Ajmera <Vipul.Ajmera@ibm.com>"

ARG PACKAGE_VERSION=v2.3.33

RUN yum install -y git wget gcc-c++ gcc && \
    yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-17-openjdk java-17-openjdk-devel && \
	export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk && \
    export PATH=$PATH:$JAVA_HOME/bin && \
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk && \
    export PATH=$PATH:$JAVA_HOME/bin

RUN wget https://github.com/adoptium/temurin16-binaries/releases/download/jdk-16.0.2%2B7/OpenJDK16U-jdk_ppc64le_linux_hotspot_16.0.2_7.tar.gz && \
    tar -C /usr/local -zxf OpenJDK16U-jdk_ppc64le_linux_hotspot_16.0.2_7.tar.gz && \
    export JAVA_HOME_16=/usr/local/jdk-16.0.2+7 && \
    export PATH=$PATH:$JAVA_HOME_16/bin && \
    ln -sf $JAVA_HOME_16/bin/java /usr/bin/java16 && \
    rm -rf OpenJDK16U-jdk_ppc64le_linux_hotspot_16.0.2_7.tar.gz


RUN wget https://github.com/AdoptOpenJDK/openjdk9-binaries/releases/download/jdk-9.0.4%2B11/OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz && \
    tar -C /usr/local -zxf OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz && \ 
    export JAVA_HOME_9=/usr/local/jdk-9.0.4+11 && \
    export PATH=$PATH:$JAVA_HOME_9/bin && \
    ln -sf $JAVA_HOME_9/bin/java /usr/bin/java9 && \
    rm -rf OpenJDK9U-jdk_ppc64le_linux_hotspot_9.0.4_11.tar.gz

RUN wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/a/apache-freemarker/toolchains.xml && \
    mkdir ~/.m2 && \
    cp toolchains.xml ~/.m2/

RUN git clone https://github.com/apache/freemarker.git && \
    cd freemarker && \
    git checkout $PACKAGE_VERSION && \
    ./gradlew "-Pfreemarker.signMethod=none" "-Pfreemarker.allowUnsignedReleaseBuild=true" --continue clean build 

CMD ["/bin/bash"]
