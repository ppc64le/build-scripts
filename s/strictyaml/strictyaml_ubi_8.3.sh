# ----------------------------------------------------------------------------
#
# Package               : strictyaml
# Version               : 1.1.0 ,1.2.0 ,1.3.1 & 1.4.4
# Source repo           : https://github.com/crdoconnor/strictyaml
# Tested on             : UBI 8.3
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Script License        : Apache License, Version 2 or later
# Maintainer            : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer            : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

if [ -z "$1" ]; then
  export VERSION=master
else
  export VERSION=$1
fi

if [ -d "strictyaml" ] ; then
  rm -rf strictyaml
fi

# Dependency installation
sudo dnf install python38  gcc-c++   gcc python38-devel -y
sudo dnf install -y  libstdc++-devel git make
sudo dnf  install -y  openssl*
sudo dnf install libffi-devel -y


# Download the repos
git clone https://github.com/crdoconnor/strictyaml


# Build and Test strictyaml
cd strictyaml
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

#replacing to supporting version traitlets 4.3.3
sed 's/5.0.4/4.3.3/g' hitch/hitchreqs.txt > tmp.txt
mv tmp.txt hitch/hitchreqs.txt


pip3 install --upgrade virtualenv
pip3 install hitchkey  Cython
pip3 install --upgrade   pytest setuptools setuptools_scm
pip3 install uvloop typed-ast regex
pip3 install pyuv psutil cryptography cffi
pip3 install -e .


#Build and test with differnt python environments
python3.8 setup.py test

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for python 3.8 environment"
else
  echo "Build & Test Success for python 3.8 environment"
fi
hk regression
ret=$?
if [ $ret -ne 0 ] ; then
  echo "regression failed for python 3.8 environment"
else
  echo "regression Success for python 3.8 environment"
fi

