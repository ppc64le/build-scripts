FROM ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install wget build-essential -y \
	&& wget https://downloads.sourceforge.net/project/mummer/mummer/3.23/MUMmer3.23.tar.gz \
	&& tar -xzvf MUMmer3.23.tar.gz \
	&& cd MUMmer3.23 \
	&& make check \
	&& make install \
	&& apt-get purge --auto-remove build-essential wget -y \
	&& rm -rf MUMmer3.23.tar.gz

ENV PATH $PATH:/MUMmer3.23

CMD ["mummer", "-h"]
