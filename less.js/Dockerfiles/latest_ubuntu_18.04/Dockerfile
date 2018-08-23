FROM ubuntu:18.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>

ENV QT_QPA_PLATFORM offscreen

RUN apt-get update \
        && apt-get install -y libfontconfig git phantomjs nodejs npm \
	&& cd / && git clone https://github.com/less/less.js && cd less.js \
        && npm install \
	&& npm install -g grunt grunt-cli \
        && npm test \
        && apt-get purge -y libfontconfig && apt-get autoremove -y

WORKDIR /less.js
CMD ["/bin/bash"]
