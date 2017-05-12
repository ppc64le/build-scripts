FROM ppc64le/openjdk:8-jre
MAINTAINER Crate.IO GmbH office@crate.io

ENV GOSU_VERSION 1.9
# install crate
ENV CRATE_VERSION 1.0.5

RUN apt-get update -y && apt-get install -y --no-install-recommends\
     curl \
     python3 \
     libhyperic-sigar-java\
    && export ARCH=$(echo $(dpkg --print-architecture) | cut -d"-" -f3) \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu\
    && groupadd crate && useradd -r -g crate crate\
    && curl -fSL -O https://cdn.crate.io/downloads/releases/crate-$CRATE_VERSION.tar.gz \
    && curl -fSL -O https://cdn.crate.io/downloads/releases/crate-$CRATE_VERSION.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 90C23FC6585BC0717F8FBFC37FAAE51A06F6EAEB \
    && gpg --batch --verify crate-$CRATE_VERSION.tar.gz.asc crate-$CRATE_VERSION.tar.gz \
    && rm -r "$GNUPGHOME" crate-$CRATE_VERSION.tar.gz.asc \
    && mkdir /crate\ 
    && tar -xf crate-$CRATE_VERSION.tar.gz -C /crate --strip-components=1\
    && rm crate-$CRATE_VERSION.tar.gz \
    && apt-get purge -y --auto-remove curl\  
    && apt-get clean

ENV PATH /crate/bin:$PATH

VOLUME ["/data"]

ADD config/crate.yml /crate/config/crate.yml
ADD config/logging.yml /crate/config/logging.yml
COPY docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

WORKDIR /data

# http: 4200 tcp
# transport: 4300 tcp
# postgres protocol ports: 5432-5532 tcp
EXPOSE 4200 4300 5432-5532

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["crate"]
