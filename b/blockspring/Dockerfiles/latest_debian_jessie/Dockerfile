FROM ppc64le/python:2.7

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update \
    &&  apt-get install -y build-essential \
    &&  cd $HOME/ && git clone https://github.com/blockspring/blockspring.py.git\
    &&  cd $HOME/blockspring.py/\
    &&  pip install -r requirements.txt\
    &&  python setup.py install && python setup.py test\
    &&  cd $HOME/ && rm -rf blockspring.py/ && apt-get purge -y build-essential && apt-get -y autoremove
	
CMD ["python", "/bin/bash"]
