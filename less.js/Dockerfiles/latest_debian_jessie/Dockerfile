FROM ppc64le/node:7.5.0

MAINTAINER "Priya Seth <sethp@us.ibm.com>

RUN apt-get update \
        && apt-get install -y libfontconfig  \
        && wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2 \
        && tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 \
        && cp phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin/ \
	&& cd / && git clone https://github.com/less/less.js && cd less.js \
        && npm install \
	&& npm install -g grunt grunt-cli \
        && npm test \
        && apt-get purge -y libfontconfig && apt-get autoremove -y

WORKDIR /less.js
CMD ["/bin/bash"]
