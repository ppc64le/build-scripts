FROM ppc64le/ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN echo "deb http://ports.ubuntu.com/ubuntu-ports xenial restricted multiverse universe"  | tee -a /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -y autoconf \
        	libtool \
        	libtool-bin \
        	make \
        	libssl-dev \
        	libxml2-dev \
        	libxslt-dev \
        	pkg-config \
		git \
	&& git clone https://github.com/lsh123/xmlsec \
	&& cd xmlsec && git checkout xmlsec-1_2_25 \
	&& sh autogen.sh \
        && make \
        && make check \
        && make install \
        && make clean \
        && cd .. && rm -rf /xmlsec \
	&& apt-get purge --autoremove pkg-config git make autoconf -y

CMD [ "bash" ]
