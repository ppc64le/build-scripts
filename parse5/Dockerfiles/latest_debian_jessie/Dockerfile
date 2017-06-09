FROM  ppc64le/node:7.5

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN git clone https://github.com/inikulin/parse5 \
	&& cd parse5 && npm install && npm test 

WORKDIR /parse5
CMD ["/bin/bash"]
