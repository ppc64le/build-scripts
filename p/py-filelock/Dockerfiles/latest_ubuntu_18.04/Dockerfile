FROM ppc64le/python:2.7
MAINTAINER  snehlata mohite <smohite@us.ibm.com>

RUN apt-get update && apt-get install -y python git  \
    && pip install setuptools \
    && git clone https://github.com/benediktschmitt/py-filelock \
    && cd py-filelock/ && python setup.py install && python test.py \
    && cd ../ && rm -rf py-filelock\

CMD ["python", "/bin/bash"]
