FROM ppc64le/node:4.7

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
        git clone https://github.com/strongloop/strongloop && cd strongloop && \
        npm install && npm test && \
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strongloop

CMD ["/bin/bash"]
