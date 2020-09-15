FROM ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		bsdmainutils libgomp1 make openmpi-bin ssh
ADD . /tmp/abyss
RUN apt-get install -y --no-install-recommends \
	        wget tar automake g++ libboost-dev libopenmpi-dev libsparsehash-dev \
	&& cd /tmp/ \
	&& wget https://github.com/bcgsc/abyss/releases/download/2.1.0/abyss-2.1.0.tar.gz --no-check-certificate \
	&& tar -zxvf abyss-2.1.0.tar.gz \
	&& cd abyss-2.1.0 \ 
	&& ./autogen.sh && ./configure --with-mpi=/usr/lib/openmpi \
	&& make install-strip \
	&& rm -rf /tmp/abyss \
	&& apt-get autoremove -y binutils \
		automake g++ libboost-dev libopenmpi-dev libsparsehash-dev

ENV TMPDIR /var/tmp
ENV SHELL=/bin/bash
ENTRYPOINT ["abyss-pe"]
CMD ["help"]
