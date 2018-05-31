FROM ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install make gcc g++ wget libncurses5-dev -y \
	&& wget https://cmake.org/files/v3.11/cmake-3.11.0.tar.gz \
	&& tar -xzvf cmake-3.11.0.tar.gz \
	&& cd cmake-3.11.0 \
	# make
	&& ./bootstrap && make && make install \
	&& cd .. && rm -rf cmake-3.11.0.tar.gz cmake-3.11.0 \
	&& apt-get purge --auto-remove wget make gcc g++ -y

CMD ["cmake", "--version"]
