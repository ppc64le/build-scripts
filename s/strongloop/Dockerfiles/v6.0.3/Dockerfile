FROM ppc64le/node:8

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential && \
        git clone https://github.com/strongloop/strongloop && cd strongloop &&  git checkout v6.0.3 && \
        npm install && npm test && \
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strongloop

ENV PATH $PATH:/strongloop/bin
ENV HOST 0.0.0.0
ENV PORT 41629
EXPOSE 41629
CMD ["slc","arc"]
