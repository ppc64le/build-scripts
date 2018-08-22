FROM node:10.9.0-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update \
	&& apt-get install -y git \
	&& git clone https://github.com/brianmcd/contextify \
	&& npm install nodeunit -g \
	&& npm install node-gyp -g \
	&& cd contextify && npm install && node-gyp rebuild && nodeunit test/ \
	&& apt-get purge -y git \
	&& apt-get -y autoremove 

WORKDIR /contextify
CMD ["/bin/bash"]
