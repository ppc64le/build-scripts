FROM python:3
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update -y \
  && apt-get install git -y \
  && pip install param nose \
  && git clone https://github.com/ioam/lancet.git \
  && cd lancet \
  && git submodule update --init \
  && python setup.py install \
  && nosetests --with-doctest 

CMD ["/bin/bash"]
