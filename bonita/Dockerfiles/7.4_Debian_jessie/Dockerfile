FROM ppc64le/openjdk:8-jre

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

ENV BONITA_VERSION 7.4.2
ENV TOMCAT_VERSION 7.0.67
ENV BONITA_SHA256 62f489362ed273f700032f5da1b4dc70a4bc74c9add2cb27e6c3be50e1e284f6

# install packages
# create user to launch Bonita BPM as non-root
# add Bonita BPM archive to the container
# grab gosu for easy step-down from root and tini for signal handling
RUN apt-get update && apt-get install -y  --no-install-recommends\
    mysql-client \
    postgresql-client \
    zip \
    && rm -rf /var/lib/apt/lists/*\
    &&  mkdir /opt/custom-init.d/\
    && groupadd -r bonita -g 1000 \
    && useradd -u 1000 -r -g bonita -d /opt/bonita/ -s /sbin/nologin -c "Bonita User" bonita\
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4\
    &&  mkdir /opt/files \
    && wget -q http://download.forge.ow2.org/bonita/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip -O /opt/files/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip \
    && echo "$BONITA_SHA256" /opt/files/BonitaBPMCommunity-${BONITA_VERSION}-Tomcat-${TOMCAT_VERSION}.zip | sha256sum -c -\
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && apt-get autoremove -y zip && apt-get clean

# create Volume to store Bonita BPM files
VOLUME /opt/bonita

COPY files /opt/files
COPY templates /opt/templates

RUN chmod +x /opt/files/startup.sh &&  chmod +x /opt/files/functions.sh && chmod +x /opt/files/config.sh\
    && chmod +x /opt/templates/setenv.sh
# expose Tomcat port
EXPOSE 8080

# command to run when the container starts
CMD ["/opt/files/startup.sh"]
