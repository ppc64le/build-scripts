FROM ppc64le/python:2.7
MAINTAINER Meghali Dhoble <dhoblem@us.ibm.com>

RUN apt-get update -y && \
    apt-get install -y gcc freetds-dev freetds-bin git && \
    export SYBASE=/usr && \
    git clone https://github.com/fbessho/python-sybase && \
    cd python-sybase && \
    python setup.py build_ext -D HAVE_FREETDS -U WANT_BULKCOPY && \
    python setup.py install && python setup.py test && \
    apt-get purge -y gcc git && apt-get autoremove -y

CMD ["/bin/bash"]
