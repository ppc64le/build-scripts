ARG JITSI_REPO=jitsi
FROM ${JITSI_REPO}/base-java

ENV GOOGLE_APPLICATION_CREDENTIALS /config/key.json

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y jq maven git && \
	apt-cleanup && \
        git clone https://github.com/jitsi/jigasi.git && cd jigasi && \
        mvn install -Dassembly.skipAssembly=false -DskipTests

COPY rootfs/ /

VOLUME ["/config", "/tmp/transcripts"]
