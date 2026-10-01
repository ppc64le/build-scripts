FROM ppc64le/ubuntu:16.04

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y git python3 python-setuptools && \
    git clone https://github.com/defnull/multipart && \
    cd multipart && \
    python setup.py install && \
    cd test && \
    python test.py

CMD ["/bin/bash"]
