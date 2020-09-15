
FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV OSSEC_HIDS_VERSION v2.9.2

ADD preloaded-vars.conf /
RUN apt-get update && \
    apt-get install -f && apt-get install -y git \
	geoip-bin \
	geoip-database \
	libgeoip-dev \
	libgeoip1 \
	libprelude-dev \
	libzmq-dev \
	check \
	valgrind \
	wget \
	build-essential \
	tzdata && \
    wget http://download.zeromq.org/czmq-2.2.0.tar.gz && \
 	tar xfz czmq-2.2.0.tar.gz && \
	cd czmq-2.2.0/ && \
 	./configure --build=ppc64le-unknown-linux-gnu && \
	make all -j && \
	make install && \
    git clone https://github.com/ossec/ossec-hids --branch=${OSSEC_HIDS_VERSION} && \
    cp /preloaded-vars.conf ./ossec-hids/etc/ && \
    cd ossec-hids && sh install.sh && \
    echo "127.0.0.1,DEFAULT_LOCAL_AGENT" > /srv/ossec/default_local_agent && \
    apt-get purge -y build-essential git wget libzmq-dev check tzdata valgrind libprelude-dev && \
    apt-get autoremove -y && \
    rm -rf czmq-2.2.0.tar.gz  czmq-2.2.0 ossec-hids

ADD start_ossec_hids.sh ./
COPY start_ossec_hids.sh /srv/ossec/
RUN chmod a+x start_ossec_hids.sh

ENV PATH=$PATH:/srv/ossec/bin

EXPOSE 1514 514

ENTRYPOINT ["sh", "start_ossec_hids.sh"]




