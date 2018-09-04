FROM ubuntu:18.04

MAINTAINER Atul Sowani <sowania@us.ibm.com>

RUN apt-get update && \
	apt-get install -y mercurial python-dev python-pip git && \
        pip install nose && \
	cd $HOME/ && hg clone https://bitbucket.org/loewis/pep381client && \
	cd $HOME/pep381client/ && python setup.py build && \
	python setup.py install && nosetests && \
	cd $HOME/ && rm -rf pep381client
	
CMD ["python", "/bin/bash"]
