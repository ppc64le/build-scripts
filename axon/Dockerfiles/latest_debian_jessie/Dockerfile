FROM node:6-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
        apt-get install -y git build-essential && \
        git clone https://github.com/tj/axon && cd axon && npm install && npm test && \
        apt-get purge -y git build-essential && apt-get autoremove -y

WORKDIR /axon

CMD ["/bin/bash"]
