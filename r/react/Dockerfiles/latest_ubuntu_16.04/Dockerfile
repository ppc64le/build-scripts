FROM node:8-stretch
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update \
	&& npm install yarn -g \
	#Build and test react
	&& git clone https://github.com/facebook/react.git \
	&& cd react && git checkout v16.4.0 \
	&& yarn install \
	&& yarn test

CMD ["/bin/bash"]
