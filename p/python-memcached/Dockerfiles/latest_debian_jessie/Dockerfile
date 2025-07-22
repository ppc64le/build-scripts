FROM ppc64le/python:2.7
MAINTAINER  snehlata mohite <smohite@us.ibm.com>

RUN apt-get update && apt-get install -y  git memcached\
    && pip install --upgrade pip\
    && git clone https://github.com/linsomniac/python-memcached\
    && cd python-memcached/ && pip install pytest && pip install -r requirements.txt\ 
    && pip install -r test-requirements.txt\
    && service memcached start\
    && python setup.py build && python setup.py install && pytest\
    && cd ../ && apt-get autoremove -y git && rm -rf python-memcached/ 

CMD ["python", "/bin/bash"]
