FROM ubuntu:18.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV QT_QPA_PLATFORM offscreen

RUN apt-get update \
        && apt-get install -y git libfontconfig phantomjs nodejs npm \
	&& cd / && git clone https://github.com/Leaflet/Leaflet && cd Leaflet \
        && npm install \
        && npm test \
        && apt-get purge -y libfontconfig && apt-get autoremove -y

WORKDIR /Leaflet
CMD ["/bin/bash"]
