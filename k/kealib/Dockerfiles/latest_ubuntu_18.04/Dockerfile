#Dockerfile for building "kealib" on Ubuntu16.04
FROM ubuntu:18.04

MAINTAINER Priya Seth <sethp@us.ibm.com>

#Clone repo and build
RUN apt-get update -y \
	&& apt-get install -y libgdal-dev libproj-dev gdal-bin mercurial cmake-curses-gui \
		python-dev python-setuptools python-pip \
    	&& hg clone https://bitbucket.org/chchrsc/kealib \
    	&& cd kealib && cmake -DCMAKE_INSTALL_PREFIX:STRING=/usr && cmake -DGDAL_INCLUDE_DIR:STRING=/usr/include/gdal \
        && cmake -DGDAL_LIB_PATH:STRING=/usr/lib && cmake -DHDF5_INCLUDE_DIR:STRING=/usr/include/hdf5/serial \
        && cmake -DHDF5_LIB_PATH:STRING=/usr/lib/powerpc64le-linux-gnu/hdf5/serial && make && make install && make test \
        && cd ../.. && apt-get -y autoremove \
	&& rm -rf kealib

CMD ["python", "/bin/bash"]

