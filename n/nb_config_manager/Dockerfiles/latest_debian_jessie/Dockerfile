#Dockerfile for building "nb_config_manager"
FROM ubuntu:18.04
MAINTAINER Priya Seth <sethp@us.ibm.com>
RUN apt-get update -y \

# Installing dependent packages
    && apt-get install -y python-dev python-pip python-setuptools git \
	pkg-config libzmq3-dev \
    && pip install -U pytest jupyter \

#Clone repo and Build
    && git clone https://github.com/Anaconda-Platform/nb_config_manager.git \
    && cd nb_config_manager \
    && python setup.py install &&  py.test \
    && apt-get purge -y git \
    && apt-get -y autoremove && cd .. && rm -rf nb_config_manager
	
CMD ["python", "/bin/bash"]	

