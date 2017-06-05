#Dockerfile for building conda-verify
FROM ppc64le/python:2.7
MAINTAINER ajay gautam <agautam@us.ibm.com>
RUN apt-get update \

# Installing dependent packages
	&& easy_install pip &&  pip install -U pip setuptools nose pyyaml \

#Clone the git repo and build
	&& git clone https://github.com/conda/conda-verify.git && cd conda-verify \

	&& python setup.py install && nosetests \
    && apt-get -y autoremove && cd .. && rm -rf conda-verify

CMD ["pip","show","conda-verify"]
CMD ["python", "/bin/bash"]
