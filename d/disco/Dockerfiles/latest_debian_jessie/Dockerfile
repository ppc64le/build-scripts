FROM ppc64le/python:2.7
MAINTAINER  snehlata mohite <smohite@us.ibm.com>

RUN apt-get update && apt-get install -y make erlang git\
    && pip install --upgrade pip\
    && git clone  https://github.com/discoproject/disco\
    && cd disco/ && make dep && make install && make test\
    && cd ../ && apt-get autoremove -y git make && rm -rf disco/

CMD ["python", "/bin/bash"]

