FROM  ppc64le/ubuntu:16.04

MAINTAINER "Archa Bhandare <archa_bhandare@persistent.co.in>"

RUN apt-get update && apt-get install -y git automake libtool build-essential && \
	git clone https://github.com/libuv/libuv.git libuv && cd libuv && \
	sh autogen.sh && ./configure && make && \
	make install && \
	apt-get purge -y git automake libtool build-essential && \
	apt-get -y autoremove

CMD ["/bin/bash"]
