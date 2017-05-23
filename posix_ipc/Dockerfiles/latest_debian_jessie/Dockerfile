#Dockerfile for building "posix_ipc" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

#Clone repo and build
RUN apt-get update -y && apt-get install -y mercurial \
    && hg clone https://bitbucket.org/philip_semanchuk/posix_ipc/src \
    && cd src/ && python setup.py install && python setup.py test \
	&& cd ../ && apt-get -y autoremove && rm -rf src/
	
CMD ["python", "/bin/bash"]
