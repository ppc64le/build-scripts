ARG JITSI_REPO=jitsi
FROM ${JITSI_REPO}/base

RUN	\
       mkdir -p /usr/share/man/man1 && \
       apt-dpkg-wrap apt-get update && \
       apt-dpkg-wrap apt-get install -y wget && \
       apt-cleanup && \
       wget https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u265-b01_openj9-0.21.0/OpenJDK8U-jdk_ppc64le_linux_openj9_8u265b01_openj9-0.21.0.tar.gz && \
       tar xzf OpenJDK8U-jdk_ppc64le_linux_openj9_8u265b01_openj9-0.21.0.tar.gz

ENV PATH=$PWD/jdk8u265-b01_openj9-0.21.0/bin:$PATH
