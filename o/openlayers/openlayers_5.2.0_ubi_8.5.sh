#! /bin/bash

# -----------------------------------------------------------------------------
# Package	: openlayers
# Version	: 5.2.0
# url       : https://github.com/openlayers/openlayers
# Tested on	: "Red Hat Enterprise Linux 8.5" (Docker)
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------


WORK_DIR=`pwd`

PACKAGE_NAME=openlayers
PACKAGE_VERSION=v5.2.0                 
PACKAGE_URL=https://github.com/openlayers/openlayers.git


# to install firefox 
dnf -y install \
	http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
	http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm

# install dependencies
yum install -y libX11-devel firefox xorg-x11-server-Xvfb glibc-devel git

# install nodejs
dnf module install nodejs:10 -y

export DISPLAY=:99
Xvfb :99 -screen 0 640x480x8 -nolisten tcp &
dbus-uuidgen > /var/lib/dbus/machine-id

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# to install 
npm install yarn -g
# build 
yarn 
# to execute tests
if ! npm test -- --browsers Firefox ; then   
	set +ex
	echo "------------------Build Success but test fails---------------------"
else
	set +ex
	echo "------------------Build and test success-------------------------"
fi

# There are 22 test-rendering failures inparity with x86.