FROM ppc64le/python:2.7

MAINTAINER Atul Sowani <sowania@us.ibm.com>

RUN apt-get update && \
    pip install --upgrade pip nose && \
	cd $HOME/ && git clone https://github.com/sprintly/ordereddict.git && \
	cd $HOME/ordereddict/ && python setup.py build && python setup.py install && nosetests && \
	cd $HOME/ && rm -rf ordereddict
	
CMD ["python", "/bin/bash"] 
