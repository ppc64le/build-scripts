FROM ppc64le/node:4.7

# Owner information
MAINTAINER "Archa Bhandare <archa_bhandare@persistent.co.in>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
	git clone https://github.com/bnoordhuis/node-heapdump.git && cd node-heapdump && \
	npm install && npm install -g node-gyp && node-gyp configure build && npm test && \
	apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /node-heapdump

CMD ["/bin/bash"]

