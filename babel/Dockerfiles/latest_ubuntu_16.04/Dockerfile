FROM node:10.9.0-stretch

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update \
	&& apt-get install build-essential -y \
	&& git clone https://github.com/babel/babel.git babel/babel \
	&& cd babel/babel \
	&& git checkout v6.26.3 \
	&& npm install yarn gulp gulp-plumber gulp-newer gulp-babel gulp-watch \ 
	&& make \
	&& make bootstrap \
	&& make test \
	&& apt-get purge --auto-remove build-essential -y

CMD ["/bin/bash"]
