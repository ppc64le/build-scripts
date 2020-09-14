FROM ppc64le/node:4.7

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
	git clone https://github.com/strongloop/strong-pubsub-bridge && cd strong-pubsub-bridge && \
	npm install && \
	#Disabling test, as it fails with same error on x86
	#npm test && \
	apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strong-pubsub-bridge

CMD ["/bin/bash"]

