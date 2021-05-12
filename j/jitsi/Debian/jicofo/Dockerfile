ARG JITSI_REPO=jitsi
FROM ${JITSI_REPO}/base-java

RUN \
	apt-dpkg-wrap apt-get update && \
#	apt-dpkg-wrap apt-get install -y jicofo && \
        apt-dpkg-wrap apt-get install -y git maven procps uuid-runtime \
        debhelper dh-systemd build-essential devscripts libxml2-utils dpkg-dev && \
        git clone https://github.com/jitsi/jicofo.git && cd jicofo && \
        cd resources && sed -i "s/dch -v/#dch -v/g" ./build_deb_package.sh && \
        ./build_deb_package.sh && \
        apt-dpkg-wrap apt-get install -y -f ../../jicofo*.deb && \
        apt-dpkg-wrap apt-get --purge remove -y git maven debhelper build-essential dpkg-dev && \
	apt-cleanup

COPY rootfs/ /

VOLUME /config

