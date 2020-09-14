FROM node:6-stretch

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
	git clone https://github.com/strongloop/strong-cluster-control.git && cd strong-cluster-control && \
	npm install && npm test && \
	apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strong-cluster-control

CMD ["/bin/bash"]

