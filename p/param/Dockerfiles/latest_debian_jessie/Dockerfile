#Dockerfile for building "param" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

#Clone repo and build
RUN apt-get update -y \
        && apt-get install -y git \
        && pip install --upgrade pip && pip install numpy ipython \
	&& easy_install nose && easy_install distribute \
	&& git clone https://github.com/ioam/param.git \
        && cd param && nosetests --with-doctest && pip uninstall -y nose ipython numpy  \
        && cd .. && apt-get remove -y git && apt-get -y autoremove && rm -rf param

CMD ["python", "/bin/bash"]

