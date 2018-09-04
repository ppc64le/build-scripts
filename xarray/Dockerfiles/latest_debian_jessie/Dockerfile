FROM ubuntu:18.04
MAINTAINER Meghali Dhoble <dhoblem@us.ibm.com>

RUN apt-get update -y && \
    apt-get install -y git python-dev python-pip python-setuptools && \
    pip install -U pytest && \
    git clone http://github.com/pydata/xarray && cd xarray && \
    python setup.py install && python setup.py test && \
    apt-get purge -y git && apt-get autoremove -y
CMD ['/bin/bash']

