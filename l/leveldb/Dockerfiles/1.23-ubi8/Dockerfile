FROM registry.access.redhat.com/ubi8/ubi:8.5 

RUN yum install -y git gcc-c++ gcc wget make  python38 yum-utils apr-devel perl openssl-devel automake autoconf libtool
 
RUN wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz && \
    tar -xvf cmake-3.21.2.tar.gz && \
    cd cmake-3.21.2 && \
    ./bootstrap && \
    make && \
    make install && \
    export PATH=$PATH:$HOME/CMake/bin

RUN git clone --recurse-submodules https://github.com/google/leveldb.git && \
    cd leveldb && \
    git checkout 1.23 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    cmake --build .

CMD ["/bin/bash"]
