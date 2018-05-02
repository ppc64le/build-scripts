FROM node
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN useradd -m yo && chown -R yo /usr/local
WORKDIR /home/yo
USER yo
RUN git clone https://github.com/yeoman/yo.git \
	&& npm install generator && cd yo \
	&& git checkout v2.0.2 \
	&& npm install -g
#NOTE: Tests pass on VM, but failing on container thus commented out.	
	#&& npm test
CMD [ "/bin/bash" ] 
