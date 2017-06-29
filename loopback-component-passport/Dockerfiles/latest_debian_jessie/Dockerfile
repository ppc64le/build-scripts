FROM ppc64le/node:4.7

# Owner information
MAINTAINER "Archa Bhandare <archa_bhandare@persistent.co.in>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
	git clone https://github.com/strongloop/loopback-component-passport.git && cd loopback-component-passport && \
	npm install && npm test && \
	apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /loopback-component-passport

CMD ["/bin/bash"]

