#Dockerfile for building "cytoolz" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

RUN apt-get update \
        && pip install --upgrade pip && virtualenv -p python2 --system-site-packages env2 \
    && git clone https://github.com/pytoolz/cytoolz.git \
        && pip install cython \
        && /bin/bash -l -c "source /env2/bin/activate && pip install nose toolz && cd /cytoolz/ && make clean && make inplace && make test \
        && pip uninstall -y toolz nose " \
        && cd ../ && pip uninstall -y cython && apt-get -y autoremove && rm -rf /cytoolz/

CMD ["python", "/bin/bash"]

