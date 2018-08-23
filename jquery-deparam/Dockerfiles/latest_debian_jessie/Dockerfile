FROM node:10.9.0-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update \
	&& apt-get install -y git \
	&& git clone https://github.com/AceMetrix/jquery-deparam \
	&& cd jquery-deparam && npm install && npm test \
	&& apt-get purge -y git \
	&& apt-get -y autoremove 

WORKDIR /jquery-deparam
CMD ["/bin/bash"]
