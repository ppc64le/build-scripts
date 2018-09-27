FROM ppc64le/node:10.11-stretch

# Owner information
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
        git clone https://github.com/strongloop/loopback-connector-remote.git && cd loopback-connector-remote && \
        npm install && npm test && \
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /accepts

CMD ["/bin/bash"]
