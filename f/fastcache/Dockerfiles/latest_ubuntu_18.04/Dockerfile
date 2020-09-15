#Dockerfile for building "fastcache" on Ubuntu16.04
FROM ubuntu:18.04
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y \
    && apt-get install -y python-dev python-setuptools python-pip git \
    && pip install pytest \
    && git clone https://github.com/pbrady/fastcache.git \
    && cd fastcache/ && python setup.py install && python setup.py test \
    && cd ../ && apt-get -y purge git && apt-get -y autoremove && rm -rf fastcache/

CMD ["python", "/bin/bash"]

