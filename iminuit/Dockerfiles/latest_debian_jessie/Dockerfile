FROM ppc64le/python:2.7

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update \
    &&  apt-get install -y libpng-dev libjpeg-dev libfreetype6-dev \
    &&  cd $HOME/ && git clone  https://github.com/iminuit/iminuit.git\
    &&  cd $HOME/iminuit\
    &&  pip install --upgrade pip\
    &&  pip install IPython matplotlib pytest pytest-cov numpy setuptools Cython\
    &&  python setup.py build_ext -i && python setup.py install && make test\
    &&  cd $HOME/ && rm -rf iminuit/ && apt-get purge -y libpng-dev libjpeg-dev libfreetype6-dev && apt-get -y autoremove
	
CMD ["python", "/bin/bash"]


