FROM node:10.9.0-stretch

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
        git clone https://github.com/strongloop/strong-service-upstart && cd strong-service-upstart && \
        npm install && npm test && \
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strong-service-upstart

CMD ["/bin/bash"]

