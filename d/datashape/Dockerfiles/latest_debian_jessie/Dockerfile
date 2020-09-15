#Dockerfile for building "datashape" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

#Clone repo and build
RUN apt-get update -y \
    && git clone https://github.com/blaze/datashape.git \
    && cd datashape && pip install -U pip && pip install -r requirements.txt && pip install pytest && pip install mock && \
        py.test -v -x --doctest-modules --pyargs datashape -rsX --tb=short && \
        pip uninstall -y mock pytest && apt-get -y autoremove && rm -rf datashape

CMD ["python", "/bin/bash"]
