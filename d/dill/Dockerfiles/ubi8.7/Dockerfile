FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

RUN yum update -y && \
        yum install -y python39-devel.ppc64le gcc gcc-c++ git &&\
        python3 -m pip install coverage numpy pytest tox && \
        git clone https://github.com/uqfoundation/dill/ && \
        cd dill && \
        python3 setup.py install

CMD ["/bin/bash"]