#Dockerfile for building "nbsetuptools" on Ubuntu16.04
FROM ppc64le/ubuntu:16.04
MAINTAINER ajay gautam <agautam@us.ibm.com>
RUN apt-get update -y &&\

# Installing dependent packages
    apt-get install -y build-essential software-properties-common &&\
    apt-get install -y python-setuptools python-dev  git &&\
    easy_install pip &&  pip install -U setuptools pytest &&\

#Clone repo and build
    git clone https://github.com/Anaconda-Platform/nbsetuptools.git && cd nbsetuptools &&\
    pip install . &&\
    python setup.py install  &&\
    pytest -k "not test_enable" &&\

    apt-get remove -y git && apt-get -y purge &&\
    apt-get -y autoremove &&\
    cd .. && rm -rf nbsetuptools
