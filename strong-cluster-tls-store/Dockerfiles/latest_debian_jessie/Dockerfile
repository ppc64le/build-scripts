FROM ppc64le/node:10.11-stretch

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
        git clone https://github.com/strongloop/strong-cluster-tls-store.git &&  cd strong-cluster-tls-store && \
        npm install && npm test && \
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strong-cluster-tls-store

CMD ["/bin/bash"]
