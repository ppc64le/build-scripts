#Dockerfile for building "constructor" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

RUN apt-get update -y && \
    git clone https://github.com/conda/constructor && \
    cd constructor/ && \
    python setup.py install && \
    cd .. && apt-get -y autoremove && rm -rf constructor

CMD ["python", "/bin/bash"]
