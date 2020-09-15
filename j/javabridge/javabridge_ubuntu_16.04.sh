# ----------------------------------------------------------------------------
#
# Package	: javabridge
# Version	: 1.0.0pr3
# Source repo	: https://github.com/LeeKamentsky/python-javabridge
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# This script has an exceptional constraint.
if [ "`id -u`" != "0" ]; then
  echo "This script should be run as sudo."
  exit
fi

# Install dependencies.
apt-get update -y
apt-get install -y gcc python python-dev python-setuptools git \
     wget bzip2 openjdk-8-jdk libgfortran3
easy_install pip

# Set up environment variables.
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export LIBRARY_PATH=$JAVA_HOME/jre/lib/ppc64le/server
export LD_LIBRARY_PATH=$LIBRARY_PATH

# Install miniconda and other conda packages.
WDIR=`pwd`
wget https://repo.continuum.io/miniconda/Miniconda3-4.2.12-Linux-ppc64le.sh -O miniconda.sh
chmod +x miniconda.sh
./miniconda.sh -b -p $WDIR/miniconda
export PATH=$WDIR/miniconda/bin:$PATH

conda install conda-build
conda create -n testenv python
conda install numpy cython nose
pip install --upgrade pip
pip install coverage coveralls

# Clone and build source code.
git clone https://github.com/LeeKamentsky/python-javabridge.git
cd python-javabridge
python setup.py develop && nosetests
