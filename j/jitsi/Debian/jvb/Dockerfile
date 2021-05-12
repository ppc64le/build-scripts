ARG JITSI_REPO=jitsi
FROM ${JITSI_REPO}/base-java

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y jq curl iproute2 git maven  procps uuid-runtime \
        debhelper dh-systemd build-essential devscripts libxml2-utils dpkg-dev && \
        git clone https://github.com/jitsi/jitsi-videobridge && cd jitsi-videobridge && \
        cd resources && ./build_deb_package.sh && \
        apt-dpkg-wrap apt-get install -y -f ../../jitsi-videobridge*.deb && \
        apt-dpkg-wrap apt-get --purge remove -y maven git debhelper build-essential dpkg-dev && \
	apt-cleanup

COPY rootfs/ /

VOLUME /config
