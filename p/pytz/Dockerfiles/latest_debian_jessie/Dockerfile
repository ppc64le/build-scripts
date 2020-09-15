#Dockerfile for building pytz
FROM ppc64le/python:2.7
MAINTAINER ajay gautam <agautam@us.ibm.com>
RUN apt-get update -y \

# Installing dependent packages
	&& easy_install pip &&  pip install -U pip setuptools pytest \

#Clone the git repo and build
	&& git clone https://github.com/newvem/pytz.git && cd pytz \
	&& python setup.py install \

#Run the tests
	&& py.test \
	&& cd .. && pip uninstall -y pytest \
    && apt-get -y autoremove && rm -rf pytz

CMD ["python", "/bin/bash"]
