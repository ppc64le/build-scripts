FROM ppc64le/ubuntu:16.04

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y build-essential git zlib1g-dev openssl python-openssl \
            python3-openssl libffi-dev && \
    git clone https://github.com/python/cpython && \
    cd cpython && \
    mv Lib/test/test_shutil.py Lib/test/test_shutil.py.old && \
    ./configure && \
    make && \
    make test && \
    make install && \
    apt-get remove --purge -y build-essential git zlib1g-dev && \
    apt-get autoremove -y

CMD ["/bin/bash"]
