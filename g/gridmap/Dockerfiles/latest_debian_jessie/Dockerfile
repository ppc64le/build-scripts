#Dockerfile for building "gridmap"
FROM ppc64le/python:2.7
MAINTAINER ajay gautam <agautam@us.ibm.com>
RUN apt-get update -y \

# Installing dependent packages
	&& apt-get install -y build-essential software-properties-common \
	&& easy_install pip &&  pip install -U setuptools nose \

#Clone repo and build
	&& git clone https://github.com/pygridtools/gridmap.git && cd gridmap \
	&& pip install e . \
	&& python setup.py install \
	&& nosetests \

	&& cd .. && pip uninstall -y nose \
    && apt-get -y autoremove && rm -rf gridmap
	
CMD ["python", "/bin/bash"]
