FROM ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install build-essential wget -y \
	&& wget https://github.com/hyattpd/Prodigal/archive/v2.6.3.tar.gz \
	&& tar -xzvf v2.6.3.tar.gz \
	&& cd Prodigal-2.6.3 \
	&& make install \
	&& cd .. && rm -rf v2.6.3.tar.gz \
	&& apt-get purge --auto-remove build-essential wget -y
	
ENV PATH $PATH:/Prodigal-2.6.3 
CMD ["prodigal"]
