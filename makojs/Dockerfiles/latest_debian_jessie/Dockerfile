FROM node:8-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN git clone https://github.com/makojs/mako \
	&& cd mako && npm install && npm test

WORKDIR /mako
CMD ["/bin/bash"]
