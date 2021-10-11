# ----------------------------------------------------------------------------
#
# Package       : sentry-sdk
# Version       : 0.14.3,0.14.4,0.18.0,0.19.5,1.0.0
# Source repo   : https://github.com/getsentry/sentry-python
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Kishor Kunal Raj <kishor.kunal.mr@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
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

if [ -d "sentry-python" ] ; then
  rm -rf sentry-python
fi

# Dependency installation
dnf update
dnf install -y git python36 make python3-devel gcc gcc-c++
ln -s /usr/bin/python3 /usr/bin/python

# Download the repos
git clone https://github.com/kishorkunal-raj/sentry-python.git


# Build and Test sentry-python
cd sentry-python/
git checkout $VERSION

ret=$?
if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

pip3 install -e .
ret=$?
if [ $ret -ne 0 ] ; then
 echo "dependency python pkg install failed "
 exit
else
	pip3 install -r test-requirements.txt
	ret=$?
	if [ $ret -ne 0 ] ; then
		echo "dependency python pkg install failed "
		exit
	else
		tox -e py3.6
	fi
fi

