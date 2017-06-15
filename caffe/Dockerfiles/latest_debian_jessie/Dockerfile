FROM ppc64le/python:2.7
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"
RUN apt-get update -y && \
    pip install --upgrade pip && pip install pytest numpy && \
    apt-get install -y cmake protobuf-compiler libgoogle-glog-dev libprotobuf-dev \ 
     libleveldb-dev libsnappy-dev libhdf5-serial-dev \ 
     liblmdb-dev libatlas-base-dev doxygen \ 
     git libncurses5-dev libboost1.55-all-dev && \ 
 
    git clone https://github.com/BVLC/caffe.git && \
    cd caffe && \ 
    sed -i.bak '/pycaffe/d' CMakeLists.txt && \ 
    cmake . -DUSE_OPENCV=0 && \
    make && \ 
    make install && \
    apt-get purge -y cmake libleveldb-dev libgflags-dev \
  	libncurses5-dev git doxygen && \
    pip uninstall -y pytest && \ 
    mv install /tmp && \
    rm -rf * && mv /tmp/install .
WORKDIR /caffe
ENV PATH $PATH:/caffe/install/bin
CMD ["/bin/bash"]



