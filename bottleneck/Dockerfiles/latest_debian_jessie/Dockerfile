#Dockerfile for building "bottleneck" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

RUN apt-get update \
        && git clone https://github.com/kwgoodman/bottleneck.git \
        && pip install --upgrade pip setuptools virtualenv && pip install tox numpy==1.11.3 \
                && cd bottleneck/ && virtualenv -p python2 --system-site-packages env2 \
                && /bin/bash -c "source env2/bin/activate" && pip install nose && make clean && make build && make test \
                && cd ../ && pip uninstall -y nose numpy tox virtualenv && apt-get -y autoremove && rm -rf /bottleneck/

CMD ["python", "/bin/bash"]

