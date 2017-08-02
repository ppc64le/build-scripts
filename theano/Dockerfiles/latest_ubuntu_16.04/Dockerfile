FROM ppc64le/ubuntu:latest
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y git build-essential python-dev python-pip \
        libopenblas-dev liblapack-dev libpng16-dev g++ libopenblas-base \
        liblapack3 python python-nose && \
    easy_install pip && \
    pip install --upgrade pip && \
    pip install nose-parameterized==0.5.0 numpy six scipy && \
    git clone https://github.com/Theano/Theano.git && \
    cd Theano && \
    python setup.py install && \
    cp -rp theano/tensor/c_code /usr/local/lib/python2.7/dist-packages/Theano-0.10.0.dev1-py2.7.egg/theano/tensor/ && \
    pip install theano && \
    cd .. && \
    apt-get -y remove --purge git build-essential python-dev python-pip \
        libopenblas-dev liblapack-dev libpng16-dev g++ && \
    apt-get autoremove -y && \
    python -c "import theano; theano.test()"

CMD [ "/bin/bash" ]

