FROM ppc64le/ubuntu:latest
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y git python python-pip && \
    pip install setuptools && \
    git clone https://github.com/ThomasWaldmann/argparse.git && \
    cd argparse && \
    python setup.py install && \
    python setup.py test && \
    cd .. && rm -rf argparse && \
    apt-get -y remove --purge git && apt-get autoremove -y

CMD ["/bin/bash"]
