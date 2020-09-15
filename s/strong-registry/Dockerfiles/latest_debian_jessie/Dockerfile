FROM ppc64le/node:10.11-stretch

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential phantomjs && \
        git clone https://github.com/strongloop/strong-registry && cd strong-registry && \
        npm install && \
        #npm test && \ #disabling test run as interactive login is required
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strong-registry

CMD ["/bin/bash"]
