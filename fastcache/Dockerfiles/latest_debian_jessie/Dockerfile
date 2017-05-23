#Dockerfile for building "fastcache" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

RUN apt-get update \
    && git clone https://github.com/pbrady/fastcache.git \
    && cd fastcache/ && python setup.py install && python setup.py test \
    && cd ../ && apt-get -y autoremove && rm -rf fastcache/

CMD ["python", "/bin/bash"]

