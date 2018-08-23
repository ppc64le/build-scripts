FROM node:10.9.0-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>

RUN apt-get update \
        && apt-get install -y git build-essential \
        && git clone https://github.com/pkrumins/node-jsmin \
        && cd node-jsmin && npm install -g \
        && apt-get purge -y git build-essential \
        && apt-get -y autoremove

CMD ["jsmin"]
