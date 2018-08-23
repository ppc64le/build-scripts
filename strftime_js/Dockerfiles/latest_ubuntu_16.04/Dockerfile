FROM node:10.9.0-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>

ENV TZ="America/Vancouver"

RUN apt-get update \
        && apt-get install -y git build-essential \
        && git clone https://github.com/samsonjs/strftime \
        && cd strftime && npm install -g && ./test.js \
        && apt-get purge -y git build-essential \
        && apt-get -y autoremove

CMD ["/bin/bash"]
