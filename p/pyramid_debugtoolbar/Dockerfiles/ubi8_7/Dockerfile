FROM registry.access.redhat.com/ubi8:8.7

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum install -y python3 git gcc-c++ python39-devel.ppc64le python3-setuptools python3-virtualenv python3-test
RUN pip3 install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets

ENV TOXENV=py39

RUN virtualenv -p python3 --system-site-packages env2 && \
    /bin/bash -c "source env2/bin/activate" && \
    pip3 install tox


ENV PATH=$PATH:/usr/local/bin/

RUN cd $SOURCE_DIR && \
    git clone https://github.com/Pylons/pyramid_debugtoolbar && \
    cd pyramid_debugtoolbar && \
    git checkout 4.12.1 && \
    python3 setup.py install

CMD ["bash"]

