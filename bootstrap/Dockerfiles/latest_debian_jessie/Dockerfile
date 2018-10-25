FROM node:10.9.0-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update \
        && apt-get install -y libfontconfig ruby ruby-dev libffi6 libffi-dev curl \
        && wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2 \
        && tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 \
        && cp phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin/ \
	&& curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
	&& curl -sSL https://get.rvm.io | bash -s -- \
	&& /bin/bash -l -c "rvm install ruby-2.4 && rvm use ruby-2.4.5 \
	&& cd / && git clone https://github.com/twbs/bootstrap && cd bootstrap \
	&& npm install -g grunt-cli \
	&& npm install phantomjs \
        && npm install \
	&& gem install bundle && bundle install" \
        && apt-get purge -y libfontconfig ruby ruby-dev libffi6 libffi-dev curl && apt-get autoremove -y

WORKDIR /bootstrap
CMD ["/bin/bash"]
