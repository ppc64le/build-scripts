ARG JITSI_REPO=jitsi
FROM ${JITSI_REPO}/rhel_base-java:latest

RUN \
	microdnf update -y && \
	microdnf install -y jq curl iproute git maven && \
        groupadd jitsi && \
        useradd -r -g jitsi --shell /bin/bash --create-home -d /usr/share/jitsi-videobridge jvb 

COPY rootfs/ /
COPY installjvb.sh /

VOLUME /config

RUN \
       echo $JAVA_HOME && \
       git clone https://github.com/jitsi/jitsi-videobridge && cd jitsi-videobridge && \
       mvn -Dmaven.repo.local=${HOME}/.m2/repository -DskipTests -Dassembly.skipAssembly=true install && \
       mvn -Dmaven.repo.local=${HOME}/.m2/repository dependency:copy-dependencies -DincludeScope=runtime && \
       cp ./jvb/target/jitsi-videobridge*.jar ./jitsi-videobridge.jar && \
       chmod +x /installjvb.sh && sh /installjvb.sh

