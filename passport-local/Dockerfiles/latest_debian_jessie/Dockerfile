OM ppc64le/node:10.11-stretch

# Owner information
maintainer "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
        git clone https://github.com/jaredhanson/passport-local.git passport-local && cd passport-local && \
        npm install && npm test && \
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /passport-local

CMD ["/bin/bash"]
