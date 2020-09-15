#Dockerfile for building "distributed" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

#Clone repo and build
RUN apt-get update -y \
    && git clone https://github.com/dask/distributed.git \
    && cd distributed && python setup.py install && python setup.py test \
    && cd .. && apt-get -y autoremove && rm -rf distributed

CMD ["python", "/bin/bash"]
