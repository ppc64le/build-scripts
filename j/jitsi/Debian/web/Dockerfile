ARG JITSI_REPO=jitsi
FROM ${JITSI_REPO}/base

ADD https://dl.eff.org/certbot-auto /usr/local/bin/

COPY rootfs/ /

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y cron nginx-extras && \
        apt-dpkg-wrap apt-get install -y git make gcc g++ nodejs npm \
           dpkg-dev libxml2-utils debhelper dh-systemd build-essential devscripts  && \
        git clone https://github.com/jitsi/jitsi-meet && cd jitsi-meet && \
        npm install && make && \
        rm -rf rm ./debian/source/format && \
        dpkg-buildpackage -us -uc && \
        apt-dpkg-wrap apt-get install -y -f ../jitsi-meet-web*.deb && \
        dpkg -x ../jitsi-meet-web-config*.deb /tmp/pkg && \
        mv /tmp/pkg/usr/share/jitsi-meet-web-config/config.js /defaults && \
        mv /usr/share/jitsi-meet/interface_config.js /defaults && \
#        cp interface_config.js /defaults && \
#        cp config.js /defaults && \
        apt-dpkg-wrap apt-get purge -y git make gcc g++ \
           dpkg-dev libxml2-utils debhelper dh-systemd build-essential devscripts && \
	apt-cleanup && \
	rm -f /etc/nginx/conf.d/default.conf && \
	rm -rf /tmp/pkg /var/cache/apt

RUN \
	chmod a+x /usr/local/bin/certbot-auto && \
	certbot-auto --noninteractive --install-only

EXPOSE 80 443

VOLUME ["/config", "/etc/letsencrypt", "/usr/share/jitsi-meet/transcripts"]
