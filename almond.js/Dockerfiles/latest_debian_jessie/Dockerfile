FROM node:10.9.0-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>

RUN apt-get update \
	&& apt-get install -y wget git build-essential \
	&& git clone https://github.com/requirejs/requirejs.git \
	&& cd requirejs/ \
	&& npm install \
	&& git clone https://github.com/requirejs/almond.git \
	&& cd almond/ \
	&& npm install \
	&& apt-get purge -y wget git build-essential \
	&& apt-get autoremove -y 

WORKDIR /requirejs/almond/
CMD ["/bin/bash"]
