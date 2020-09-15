FROM ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install make git gcc -y \
	&& git clone https://github.com/ndevilla/iniparser.git \
	&& cd iniparser && git checkout v4.1 \
	&& make && make check \
	&& make example \
	&& apt-get purge --auto-remove make git gcc -y 

CMD ["/bin/bash"]
