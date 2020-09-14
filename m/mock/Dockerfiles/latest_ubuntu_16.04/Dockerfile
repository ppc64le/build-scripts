FROM ppc64le/ubuntu:16.04

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y python-setuptools git && \
    git clone https://github.com/testing-cabal/mock && \
    cd mock && \
    python setup.py install && \
    apt-get remove --purge -y git && apt-get autoremove -y

CMD ["/bin/bash"]
