FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>

RUN apt-get update && apt-get install -y \
        git \
        make \
	&& git clone https://github.com/makamaka/JSON.git \
	&& cd JSON && perl Makefile.PL && make && make test && make install \
	&& apt-get purge -y git make && apt-get autoremove -y

CMD ["/bin/bash"]

