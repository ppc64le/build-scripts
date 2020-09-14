FROM ppc64le/node:4.7

# Owner information
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
        git clone https://github.com/strongloop/strongloop --branch=v6.0.3 && cd strongloop && \
        npm install && npm test && \
        mv ./bin/slc.js ./bin/slc && \
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strongloop
ENV PATH $PATH:/strongloop/bin
ENV HOST 0.0.0.0
ENV PORT 41629
EXPOSE 41629
CMD ["slc","arc"]

