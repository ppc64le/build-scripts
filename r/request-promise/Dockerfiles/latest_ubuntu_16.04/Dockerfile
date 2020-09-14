FROM node:10.9.0-stretch
MAINTAINER "Priya Seth <sethp@us.ibm.com>"
ENV V_REQUEST latest
ENV COVERALLS_REPO_TOKEN SIAeZjKYlHK74rbcFvNHMUzjRiMpflxve
ENV VERSION v4.2.2

RUN apt-get update -y \
	&& git clone https://github.com/request/request-promise.git \
	&& cd request-promise && git checkout $VERSION \
	&& npm install tough-cookie \
	&& npm install request@$V_REQUEST \
	&& npm install \
	&& npm test \
	&& npm -g install
ENV NODE_PATH /usr/local/lib/node_modules/
CMD ["/bin/bash"]
