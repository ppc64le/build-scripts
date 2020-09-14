FROM ppc64le/ubuntu:latest
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y git build-essential python-dev python-pip \
        libopenblas-dev liblapack-dev libpng16-dev g++ libopenblas-base \
        liblapack3 python python-nose && \
    easy_install pip && \
    pip install --upgrade pip && \
    pip install nose-parameterized==0.5.0 numpy six scipy parameterized && \
    git clone https://github.com/Theano/Theano.git && \
    cd Theano && \
    python setup.py install && \
    cp -rp theano/tensor/c_code /usr/local/lib/python2.7/dist-packages/Theano-*-py2.7.egg/theano/tensor/ && \
    pip install theano && \
    cd .. && \
    python -c "import theano; theano.test()" && \
    pip uninstall -y parameterized && \
    apt-get -y remove --purge git build-essential python-dev python-pip \
        libopenblas-dev liblapack-dev libpng16-dev g++ && \
    apt-get autoremove -y && \

CMD [ "/bin/bash" ]

