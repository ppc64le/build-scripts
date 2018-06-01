FROM python:3
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"
RUN apt-get update -y \
	&& apt-get install -y python-docutils libncursesw5-dev \
		graphviz \
		gcc g++ make autoconf automake libpcre3-dev pkg-config \
	&& git clone https://github.com/varnishcache/varnish-cache \
	&& cd varnish-cache \
	&& git checkout varnish-4.1.10 \
	&& sh autogen.sh \
	&& sh configure \
	&& make \
	&& make install \
	&& apt-get purge --auto-remove g++ make autoconf automake libpcre3-dev pkg-config -y

EXPOSE 80

CMD ["varnishd", "-b", "80", "-F"]
