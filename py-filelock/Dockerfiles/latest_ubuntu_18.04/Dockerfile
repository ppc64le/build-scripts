FROM ubuntu:18.04
MAINTAINER  snehlata mohite <smohite@us.ibm.com>

RUN apt-get update && apt-get install -y python git  \
    && git clone https://github.com/benediktschmitt/py-filelock \
    && cd py-filelock/ && python setup.py install && python test.py \
    && cd ../ && rm -rf py-filelock\

CMD ["python", "/bin/bash"]
