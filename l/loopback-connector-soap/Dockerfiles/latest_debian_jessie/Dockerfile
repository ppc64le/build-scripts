FROM ppc64le/node:10.9.0-stretch

# Owner information
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
	git clone https://github.com/strongloop/loopback-connector-soap.git && cd loopback-connector-soap && \
	npm install && npm test && \
	apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /loopback-connector-soap

CMD ["/bin/bash"]
