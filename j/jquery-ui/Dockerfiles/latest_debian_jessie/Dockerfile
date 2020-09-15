FROM ppc64le/openjdk:8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>

RUN apt-get update \
        && apt-get install -y libfontconfig build-essential \
        && wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2 \
        && tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 \
        && cp phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin/ \
	&& git clone https://github.com/nodejs/node.git && cd node && git checkout v7.4.0 && ./configure && make && make install \
	&& cd / && git clone https://github.com/jquery/jquery-ui && cd jquery-ui \
        && npm install \
        && npm test \
        && apt-get purge -y libfontconfig build-essential && apt-get autoremove -y

WORKDIR /jquery-ui
CMD ["/bin/bash"]
