#Dockerfile for building "petlx" on Ubuntu16.04
FROM ppc64le/ubuntu:16.04
MAINTAINER ajay gautam <agautam@us.ibm.com>
RUN apt-get update -y &&\

# Installing dependent packages
    apt-get install -y build-essential software-properties-common &&\
    apt-get install -y python-setuptools python-dev  git libz-dev libbz2-dev liblzma-dev &&\
    easy_install pip &&  pip install -U setuptools pytest nose &&\
	
#Clone source and install package
    git clone https://github.com/alimanfoo/petlx.git &&\
    cd petlx && pip install -r test_requirements.txt &&\
    python setup.py install && py.test &&\
	
#Remove Build time dependencies
    apt-get remove -y git libz-dev libbz2-dev liblzma-dev &&\
    apt-get -y purge && apt-get -y autoremove && cd .. && rm -rf petlx
