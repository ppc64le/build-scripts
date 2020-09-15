FROM ppc64le/ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update && \
    apt-get install libqt4-dev make cmake mercurial gcc g++ gfortran python-dev -y && \
    hg clone https://bitbucket.org/eigen/eigen  && \
    cd eigen && hg pull && hg update default && \
    cd .. && mkdir build && cd build && \
    cmake --DCMAKE_INSTALL_PREFIX=/usr/local/eigen ../eigen && \
    make install && \    
    apt-get remove libqt4-dev make cmake mercurial gfortran python-dev g++ -y && apt-get purge -y && cd .. && rm -rf eigen 


