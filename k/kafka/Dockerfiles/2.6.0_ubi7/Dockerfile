FROM registry.access.redhat.com/ubi7

ENV VERSION=2.6.0

RUN yum update -y && \
    yum install -y git unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    cd $HOME && \
    git clone https://github.com/apache/kafka && cd kafka && \
    git checkout ${VERSION} && \
    ./gradlew clean && ./gradlew jar && ./gradlew releaseTarGz -x signArchives