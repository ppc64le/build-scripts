FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && apt-get install -y make \
	gcc \
	git \
	tcl \
	&& git clone https://github.com/antirez/redis.git && \
	cd redis && \
	git checkout 3.2.9 && \
	make V=1 && \
	make install && \
	cd / && \
	rm -fr redis && \
	apt-get purge -y make gcc git && apt-get autoremove -y

# Creating volume directory so we can share data between container and host
VOLUME /data

# Started redis server as a default command.
CMD ["redis-server"]

# Exposing port at out side world.
EXPOSE 6379

