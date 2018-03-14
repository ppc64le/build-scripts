# Dockerfile to build mxnet on Centos_7.4 (GPU)

FROM nvidia/cuda-ppc64le:9.0-cudnn7-devel-centos7

# Building MXNet from source is a 2 step process.
   # 1.Build the MXNet core shared library, libmxnet.so, from the C++ sources.
   # 2.Build the language specific bindings. Example - Python bindings, Scala bindings.

RUN yum update -y && \
	# 1. ------------ Build the MXNet core shared library ------------------ 
        # libraries for building mxnet c++ core on ubuntu
	yum groupinstall 'Development Tools' -y && \
	yum install -y wget git cmake && \
	wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
	rpm -ivh epel-release-latest-7.noarch.rpm && \
	yum update -y && \
	yum install -y openblas-devel.ppc64le opencv-devel.ppc64le && \
	ln -s /usr/include/openblas/* /usr/include/  \
	&& \
	# Download MXNet sources and build MXNet core shared library
        git clone --recursive https://github.com/apache/incubator-mxnet.git mxnet && \
        cd mxnet && \
	git clone https://github.com/NVlabs/cub && \
        git checkout 1.0.0 && \
        git submodule update --recursive && \
	make -j $(nproc) USE_OPENCV=1 USE_BLAS=openblas USE_CUDA=1 USE_CUDA_PATH=/usr/local/cuda USE_CUDNN=1 USE_PROFILER=1 && \
        rm -rf build \
        && \
	# 2. -------------- Build the MXNet Python binding ------------------
        # install libraries for mxnet's python package on ubuntu
        yum update -y && \
	yum install -y python-devel.ppc64le  python-setuptools  python-pip numpy && \
	# Install the MXNet Python binding.
        cd python && \
        pip install --upgrade pip && \
        pip install -e . && \
	yum remove -y  'Development Tools' git cmake wget && \
	yum autoremove -y && \
	yum clean all && \
	rm -rf /epel-release-latest-7.noarch.rpm  

ENV PYTHONPATH=/mxnet/python
CMD  bash

# Install Graphviz. (Optional, needed for graph visualization using mxnet.viz package).
  # yum install -y graphviz
  # pip install graphviz

# ------------------ Running the unit tests (run the following from MXNet root directory)-------------------
 # pip install pytest nose numpy==1.11.0 scipy pytest-xdist
 # yum install -y scipy
 # python -m pytest -n1 -v tests/python/unittest
 # python -m pytest -n1 -v tests/python/train

# On RHEL following 5 tests are failing on both the platforms (ppc64le and X86),we can ignore these failures 
# 1.tests/python/unittest/test_operator.py::test_laop, 
# 2.tests/python/unittest/test_operator.py::test_laop_2,
# 3.tests/python/unittest/test_operator.py::test_laop_3, and 
# 4.tests/python/unittest/test_operator.py::test_laop_4
# 5.tests/python/unittest/test_ndarray.py::test_ndarray_indexing  
