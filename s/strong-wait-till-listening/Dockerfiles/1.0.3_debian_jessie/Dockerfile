FROM node:6-stretch

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
	wget https://github.com/strongloop/strong-wait-till-listening/archive/v1.0.3.tar.gz && \
	tar -zxvf v1.0.3.tar.gz && cd strong-wait-till-listening-1.0.3 && \
	npm install && npm test && \
	apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strong-wait-till-listening-1.0.3

CMD ["/bin/bash"]
