FROM  ppc64le/node:7.5

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update \
	&& apt-get install -y git \
	&& git clone https://github.com/usablica/intro.js \
	&& cd intro.js && npm install \
	&& apt-get purge -y git \
	&& apt-get -y autoremove 

WORKDIR /intro.js
CMD ["/bin/bash"]
