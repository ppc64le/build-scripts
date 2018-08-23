FROM ubuntu:18.04

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y git python python-setuptools tox && \
    git clone https://github.com/dimazest/google-ngram-downloader && \
    cd google-ngram-downloader && \
    python setup.py build && \
    python setup.py install && \
    tox -e py27-with-doctest && \
    apt-get remove --purge -y git tox && apt-get autoremove -y

CMD ["/bin/bash"]
