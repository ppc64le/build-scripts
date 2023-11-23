#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cloudpickle
# Version          : v3.0.0
# Source repo      : https://github.com/cloudpipe/cloudpickle.git
# Tested on        : UBI 8.7
# Language         : Python
# Travis-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Mohit Pawar <mohit.pawar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

yum install -y gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget
yum install -y python39 python39-devel python39-setuptools

python3 -m ensurepip --upgrade

git clone https://github.com/cloudpipe/cloudpickle.git
cd cloudpickle
git checkout v3.0.0

pip3 install tox 
python3 -m pip install -r dev-requirements.txt
#python3 setup.py install
python3 -m pip install tox --ignore-installed
tox -e py3
