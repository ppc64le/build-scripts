FROM node:10.9.0-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>

RUN apt-get update \
        && apt-get install -y git build-essential \
        && git clone https://github.com/julienw/jquery-trap-input \
        && cd jquery-trap-input && npm install -g bower && bower --allow-root install \
        && apt-get purge -y git build-essential \
        && apt-get -y autoremove

CMD ["/bin/bash"]
