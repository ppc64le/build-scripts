FROM ppc64le/python:2.7

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update \
    &&  cd $HOME/ && git clone https://github.com/Pylons/pyramid_debugtoolbar\
    &&  cd $HOME/pyramid_debugtoolbar\
    &&  pip install --upgrade pip\
    &&  pip install mock ipython_genutils pytest traitlets tox setuptools\
    &&  export TOXENV=py27 && python setup.py install && tox\
    &&  cd $HOME/ && rm -rf pyramid_debugtoolbar/  
	
CMD ["python", "/bin/bash"]
