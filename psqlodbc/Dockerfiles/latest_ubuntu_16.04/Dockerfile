FROM ppc64le/ubuntu:16.04
MAINTAINER Meghali Dhoble dhoblem@us.ibm.com

RUN apt-get update -y && \
	apt-get install -y unixodbc unixodbc-dev libpq-dev git make g++ build-essential autoconf && \
	git clone https://github.com/Distrotech/psqlodbc.git && \
	cd $PWD/psqlodbc && \
	./configure --build=ppc64le-linux && make && ./bootstrap && make check && \
	apt-get purge -y git make g++ build-essential autoconf && apt-get autoremove -y
