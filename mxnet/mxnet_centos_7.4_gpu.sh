# ----------------------------------------------------------------------------
#
# Package       : MXNet
# Version       : 1.0.0
# Source repo   : https://github.com/apache/incubator-mxnet.git
# Tested on     : centos_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Sandip Giri <sgiri@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -x

# Assumption:
# CUDA 9 and cuDNN 7 are installed.

# Building MXNet from source is a 2 step process.
   # 1.Build the MXNet core shared library, libmxnet.so, from the C++ sources.
   # 2.Build the language specific bindings. Example - Python bindings, Scala bindings.

# ---------------------------- Build the MXNet core shared library -------------------------------
# Install build tools and git
sudo yum update -y
sudo yum groupinstall 'Development Tools' -y
sudo yum install -y git wget cmake

# Install OpenBLAS
# MXNet uses BLAS and LAPACK libraries for accelerated numerical computations on CPU machine.
# There are several flavors of BLAS/LAPACK libraries - OpenBLAS, ATLAS and MKL. In this step we install OpenBLAS.
# You can choose to install ATLAS or MKL.
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -ivh epel-release-latest-7.noarch.rpm
sudo yum update -y
sudo yum install -y openblas-devel.ppc64le
sudo ln -s /usr/include/openblas/* /usr/include/

# Install OpenCV.
# MXNet uses OpenCV for efficient image loading and augmentation operations.
sudo yum install -y opencv-devel.ppc64le

# Download MXNet sources and build MXNet core shared library
git clone --recursive https://github.com/apache/incubator-mxnet.git mxnet
cd mxnet
git clone https://github.com/NVlabs/cub
git checkout 1.0.0
make -j $(nproc) USE_OPENCV=1 USE_BLAS=openblas USE_CUDA=1 USE_CUDA_PATH=/usr/local/cuda USE_CUDNN=1 USE_PROFILER=1
rm -rf build
# Note - USE_OPENCV and USE_BLAS are make file flags to set compilation options to use OpenCV and BLAS library.
# You can explore and use more compilation options in make/config.mk.


# ------------------------------ Build the MXNet Python binding ---------------------------------
# Install prerequisites - python, setup-tools, python-pip and numpy.
sudo yum install -y python-devel.ppc64le  python-setuptools  python-pip numpy

# Install the MXNet Python binding.
cd python
sudo pip install --upgrade pip
sudo pip install -e .

# Install Graphviz. (Optional, needed for graph visualization using mxnet.viz package).
sudo yum install -y graphviz
sudo pip install graphviz


# ------------------ Running the unit tests (run the following from MXNet root directory)-------------------
cd ..
sudo pip install pytest nose numpy==1.11.0 scipy pytest-xdist
sudo yum install -y scipy
python -m pytest -n1 -v tests/python/unittest
python -m pytest -n1 -v tests/python/train

# Note : If the tests are failing with " Segmentation fault  (core dumped)" error, 
# then we need to rerun the test command 2 or 3 times to pass the tests.  

# On RHEL following 5 tests are failing on both the platforms (ppc64le and X86),we can ignore these failures 
# 1.tests/python/unittest/test_operator.py::test_laop, 
# 2.tests/python/unittest/test_operator.py::test_laop_2,
# 3.tests/python/unittest/test_operator.py::test_laop_3, and 
# 4.tests/python/unittest/test_operator.py::test_laop_4
# 5.tests/python/unittest/test_ndarray.py::test_ndarray_indexing
