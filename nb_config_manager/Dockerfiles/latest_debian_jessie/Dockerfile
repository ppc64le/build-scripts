#Dockerfile for building "nb_config_manager"
FROM ppc64le/python:2.7
MAINTAINER ajay gautam <agautam@us.ibm.com>
RUN apt-get update -y \

# Installing dependent packages
    && pip install -U pip setuptools
RUN pip install -U pytest jupyter \
    && apt-get install -y pkg-config libzmq-dev \

#Clone repo and Build
    && git clone https://github.com/Anaconda-Platform/nb_config_manager.git \
    && cd nb_config_manager \
    && python setup.py install &&  py.test \
    && apt-get -y autoremove && cd .. && rm -rf nb_config_manager
	
CMD ["python", "/bin/bash"]	

