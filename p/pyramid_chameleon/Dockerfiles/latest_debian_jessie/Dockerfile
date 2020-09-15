FROM ppc64le/python:2.7

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update \
    &&  cd $HOME/ && git clone https://github.com/Pylons/pyramid_chameleon\
    &&  cd $HOME/pyramid_chameleon\
    &&  pip install --upgrade pip\
    &&  pip install virtualenv mock ipython_genutils pytest traitlets tox\
    &&  export TOXENV=py27 && python setup.py install && tox\
    &&  cd $HOME/ && rm -rf pyramid_chameleon/  
	
CMD ["python", "/bin/bash"]
