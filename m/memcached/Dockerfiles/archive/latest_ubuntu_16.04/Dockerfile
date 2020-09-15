FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

# Install build dependencies
RUN apt-get update && apt-get install -y libtool \
	git \
	automake \
	make \
	wget \
	tar \
	gcc \
	libevent-dev \
	perl \
	&& git clone https://github.com/memcached/memcached.git && cd memcached && ./autogen.sh && ./configure && make && make test && make install \
	&& apt-get purge -y git automake gcc && apt-get autoremove -y

# Creating volume directory so we can share data between container and host
VOLUME /data

# Expose 11211 port to out sideworld so they can communicate with container
EXPOSE 11211

#When container start it will run memcached command
ENTRYPOINT ["memcached"]

# Argument supplied to entry point
CMD ["-u", "root"]
