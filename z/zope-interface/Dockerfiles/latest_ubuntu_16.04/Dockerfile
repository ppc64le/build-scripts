FROM ppc64le/ubuntu:16.04

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y git python python-dev python-setuptools \
    build-essential && \
    git clone https://github.com/zopefoundation/zope.interface && \
    cd zope.interface && \
    python setup.py test && \
    apt-get remove --purge -y git

CMD ["/bin/bash"]
