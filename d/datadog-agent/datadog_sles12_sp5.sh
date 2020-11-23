# ----------------------------------------------------------------------------
#
# Package        : Datadog-Agent
# Version        : 7.21.0
# Source repo    : https://github.com/DataDog/datadog-agent.git
# Tested on      : SLES 12 SP5
# Script License : Apache License, Version 2 or later
# Maintainer     : Nishikant Thorat <Nishikant.Thorat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
DATADOG_DIR=$HOME/Datadog
PYTHON_INSTALL_DIR=$DATADOG_DIR/Python_install
PYTHON_VENV=Datadog_agent_venv
mkdir -p $DATADOG_DIR && cd $DATADOG_DIR
#
# NOTE: libffi/ libffi-devel, installed by this script are from repo "https://download.opensuse.org/repositories/devel:/gcc/SLE-12/", and can be uninstalled on need basis.
#
zypper in -y curl gzip awk git libffi-devel-gcc5 libffi4-5.5.0+r253576-4.1.ppc64le wget  tar 
zypper in -y openssl openssl-devel make gcc gcc-c++
#
# Install Python v3.8.6 from source
#
wget https://www.python.org/ftp/python/3.8.6/Python-3.8.6.tgz
tar -xzvf Python-3.8.6.tgz
cd Python-3.8.6
./configure --enable-shared --prefix=$PYTHON_INSTALL_DIR  --exec-prefix=$PYTHON_INSTALL_DIR
make
make install
# Fix for handling empty pyconfig.h
cp pyconfig.h  $PYTHON_INSTALL_DIR/include/python3.8/
cd $DATADOG_DIR
#
# Create virtual environment for datadog 
#
export LD_LIBRARY_PATH=$PYTHON_INSTALL_DIR/lib:$LD_LIBRARY_PATH
export PATH=$PYTHON_INSTALL_DIR/bin:$PATH
python3.8 -m venv --system-site-packages $PYTHON_VENV
source $PYTHON_VENV/bin/activate

wget https://dl.google.com/go/go1.13.5.linux-ppc64le.tar.gz 
tar -C $DATADOG_DIR -xzf go1.13.5.linux-ppc64le.tar.gz 
rm -rf go1.13.5.linux-ppc64le.tar.gz
export PATH=$PATH:$DATADOG_DIR/go/bin 
export GOPATH=$DATADOG_DIR
go version
python3 -m pip install --upgrade pip 
#
# Compile and Install cmake 
#
mkdir -p $DATADOG_DIR/cmake
wget http://www.cmake.org/files/v3.16/cmake-3.16.4.tar.gz 
tar xzf cmake-3.16.4.tar.gz
rm -rf  cmake-3.16.4.tar.gz
cd cmake-3.16.4 
./bootstrap --prefix=$DATADOG_DIR/cmake
make 
make install 
cmake --version
export PATH=$PATH:$DATADOG_DIR/cmake/bin
cd $DATADOG_DIR
#
# Get datadog-agent, build and execute unit tests
#
git clone https://github.com/DataDog/datadog-agent.git $GOPATH/src/github.com/DataDog/datadog-agent
cd $GOPATH/src/github.com/DataDog/datadog-agent
export PATH=$PATH:/$GOPATH/bin
pip3 install git+https://github.com/donnemartin/gitsome.git
python -m pip install --upgrade pip

pip install -r requirements.txt 
invoke deps 
invoke agent.build --build-exclude=systemd --python-home-3=$DATADOG_DIR/$PYTHON_VENV
#
# NOTE: Need to check version for golang, v.1.27 works but latest 1.32 is available
#
GO111MODULE=on go get github.com/golangci/golangci-lint/cmd/golangci-lint
#
# NOTE: There are 3 failures in test execution, one failure matches with failures on intel(and passes when ran individually).
# ("INTEGRATION=1 go test -v ./pkg/trace/test/testsuite") Other two works with increased timeout value. Investigation is in progress
# Disabling following test execution 
#
#invoke  -e test --build-exclude=systemd --python-runtimes 3 --coverage --race --profile --fail-on-fmt --cpus 3
# 
# Removing cmake 
#
cd $DATADOG_DIR/cmake-3.16.4
make uninstall
# zypper remove -y libffi-devel-gcc5 libffi4-5.5.0+r253576-4.1.ppc64le
deactivate
echo "-----------------------------------------------------------"
echo " Python installed Directory - $PYTHON_INSTALL_DIR"
echo " Python virtual environment - $DATADOG_DIR/$PYTHON_VENV"
echo "-----------------------------------------------------------"
