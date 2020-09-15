FROM ubuntu:18.04
MAINTAINER Meghali Dhoble <dhoblem@us.ibm.com>

RUN apt-get update -y && \
    apt-get install -y git python python-pip && \
        pip install mock pytest && \
    git clone http://github.com/pydata/xarray && cd xarray && \
    python setup.py install && py.test xarray --verbose && \
    apt-get purge -y git && apt-get autoremove -y
CMD ["/bin/bash"]
