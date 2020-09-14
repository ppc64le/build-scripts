FROM node:8-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>"
ENV PATH=./node_modules/.bin:$PATH
RUN git clone https://github.com/inikulin/parse5 \
        && cd parse5 && git submodule update --init --recursive && npm install --unsafe-perm && npm test

WORKDIR /parse5
CMD ["/bin/bash"]

