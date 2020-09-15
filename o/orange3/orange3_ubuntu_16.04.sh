# ----------------------------------------------------------------------------
#
# Package	: orange3
# Version	: 3.4.5
# Source repo	: https://github.com/biolab/orange3.git
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

WDIR=`pwd`

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y qt5-qmake qt5-default wget build-essential wget \
  python3 python3-dev python3-pip git libffi-dev libssl-dev virtualenv \
  pyqt5-dev python3-pyqt5 libpq-dev gfortran libatlas-base-dev freetds-dev
virtualenv --python=python3 --system-site-packages orange3venv
source $wdir/orange3venv/bin/activate

# Install sip and pyqt5
cd $WDIR
wget https://sourceforge.net/projects/pyqt/files/sip/sip-4.19.3/sip-4.19.3.tar.gz
tar -xzf sip-4.19.3.tar.gz
cd sip-4.19.3
python configure.py
make
sudo make install

cd $WDIR
wget https://sourceforge.net/projects/pyqt/files/PyQt5/PyQt-5.9/PyQt5_gpl-5.9.tar.gz
tar -xzf PyQt5_gpl-5.9.tar.gz
cd PyQt5_gpl-5.9
python3 configure.py --confirm-license
make
sudo make install

# Clone and build source code.
cd $WDIR
git clone https://github.com/biolab/orange3.git
cd orange3
sudo -H pip3 install --upgrade pip --upgrade setuptools
sudo -H pip3 install beautifulsoup4 docutils numpydoc recommonmark Sphinx
sudo -H pip3 install -r requirements-dev.txt
sudo -H pip3 install -r requirements-core.txt  # For Orange Python library
sudo -H pip3 install -r requirements-gui.txt   # For Orange GUI
sudo -H pip3 install -r requirements-sql.txt   # To use SQL support
sudo -H pip3 install -e .

# Build and Install.
sudo -H python3 setup.py build
sudo -H python3 setup.py install
sudo -H python3 setup.py test
