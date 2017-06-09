FROM  ppc64le/node:7.5

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN git clone https://github.com/makojs/core \
	&& cd core && npm install && npm test

WORKDIR /core
CMD ["/bin/bash"]
