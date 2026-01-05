FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Build node from source
RUN apt-get update && apt-get install -y build-essential git valgrind \
	&& git clone https://github.com/Cyan4973/xxHash \
	&& cd xxHash && make && make test && make install \
	&& apt-get purge -y build-essential git valgrind \	
	&& apt-get -y autoremove \
	&& rm -rf /xxHash

CMD ["/usr/local/bin/xxhsum"]

