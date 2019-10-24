#This Dockerfile has been adapted from the official version at
#https://github.com/docker-library/memcached
FROM registry.access.redhat.com/ubi8/ubi:latest

###Required Labels
LABEL name="memcached" \
      maintainer="sethp@us.ibm.com" \
      vendor="memcached" \
      version="1.5.16" \
      release="1" \
      summary="Red Hat UBI memcached" \
      description="Red Hat UBI memcached Application"

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd --system --gid 11211 memcache && useradd --system --gid memcache --uid 11211 memcache

# ensure SASL's "libplain.so" is installed as per https://github.com/memcached/memcached/wiki/SASLHowto
RUN set -eux; \
	yum update -y \
	yum install -y cyrus-sasl-lib

ENV MEMCACHED_VERSION 1.5.16
ENV MEMCACHED_SHA1 06a9661638cb20232d0ccea088f52ca10b959968
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib

RUN set -x \
	\
	&& yum update -y \
	&& yum install -y \
		ca-certificates \
		gcc \
		libtool \
		autoconf \
		cyrus-sasl-devel \
		make \
		perl \
		wget \
	&& wget https://github.com/libevent/libevent/releases/download/release-2.1.10-stable/libevent-2.1.10-stable.tar.gz \
	&& tar -zxvf libevent-2.1.10-stable.tar.gz \
	&& cd libevent-2.1.10-stable \
	&& ./autogen.sh && ./configure && make && make install \
	&& cd - && wget -O memcached.tar.gz "https://memcached.org/files/memcached-$MEMCACHED_VERSION.tar.gz" \
	&& echo "$MEMCACHED_SHA1  memcached.tar.gz" | sha1sum -c - \
	&& mkdir -p /usr/src/memcached \
	&& tar -xzf memcached.tar.gz -C /usr/src/memcached --strip-components=1 \
	&& rm memcached.tar.gz \
	&& cd /usr/src/memcached \
	&& gnuArch="${arch}" \
	&& enableExtstore="$( \
# https://github.com/docker-library/memcached/pull/38
		case "$gnuArch" in \
# https://github.com/memcached/memcached/issues/381 "--enable-extstore on s390x (IBM System Z mainframe architecture) fails tests"
			s390x-*) ;; \
			*) echo '--enable-extstore' ;; \
		esac \
	)" \
	&& ./configure \
		--build="$gnuArch" \
		--enable-sasl \
		--enable-sasl-pwdb \
		$enableExtstore \
	&& make -j "$(nproc)" \
	\
# TODO https://github.com/memcached/memcached/issues/382 "t/chunked-extstore.t is flaky on arm32v6"
	&& make test \
	&& make install \
	\
	&& cd / && rm -rf /usr/src/memcached \
	&& yum remove make gcc wget -y \
	&& memcached -V

RUN mkdir /licenses
COPY licensing.txt /licenses

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

USER memcache
EXPOSE 11211
CMD ["memcached"]
