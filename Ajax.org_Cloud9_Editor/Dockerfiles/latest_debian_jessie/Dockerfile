#Dockerfile for Ace (Ajax.org Cloud9 Editor)
FROM ppc64le/node:7.5

MAINTAINER Kumar Abhinav

RUN apt-get update \
	&& apt-get install -y git \
	&& git clone https://github.com/ajaxorg/ace.git && cd ace \
	&& npm install \
	&& node ./Makefile.dryice.js \
	&& node lib/ace/test/all.js \
	&& apt-get purge -y git \
	&& apt-get -y autoremove

WORKDIR /ace
CMD ["/bin/bash"]

