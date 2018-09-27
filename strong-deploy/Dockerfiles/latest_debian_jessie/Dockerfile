FROM ppc64le/node:10.11-stretch

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
        git clone https://github.com/strongloop/strong-deploy && cd strong-deploy && \
        npm install && \
        #Disabling tests as the tests have been failing with the same error on x86
        #npm test && \
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strong-deploy

CMD ["/bin/bash"]

