# ----------------------------------------------------------------------------------------------------
#
# Package       : wiotp-utils-py
# Version       : 7.0.3, 7.0.5
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

#Variables
NAME=wiotp-utils-py
VERSION=7.0.3
ARCH=$(arch)

#Extract version from command line
echo "Usage: $0 [-v <VERSION>]"
echo "VERSION is an optional paramater whose default value is ${VERSION}, not all versions are supported."
VERSION="${1:-$VERSION}"

#Ask for credentials
echo -n "Please enter your github.ibm.com personal access token: "
read TOKEN
echo -n "Please enter your W3 Username: "
read W3_USERNAME
echo -n "Please enter your W3 Password:"
read -s W3_PASSWORD
echo

#Exit on error, echo commands
set -ex
REPO=https://${TOKEN}@github.ibm.com/wiotp/${NAME}.git

#Install dependencies
dnf -y install \
http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
yum install git python2 python2-devel python3 python3-devel libev libev-devel wget make gcc gcc-c++ cyrus-sasl-devel redhat-rpm-config -y
dnf install -y http://mirror.centos.org/centos/8/PowerTools/${ARCH}/os/Packages/pandoc-common-2.0.6-5.el8.noarch.rpm
dnf install -y http://mirror.centos.org/centos/8/PowerTools/${ARCH}/os/Packages/pandoc-2.0.6-5.el8.${ARCH}.rpm
pip2 install pypandoc pytest tox
pip3 install pypandoc pytest tox
if [ ! -d /opt/librdkafka ] ; then
	cd /opt
	git clone https://github.com/edenhill/librdkafka.git
	cd librdkafka
	./configure --install-deps
	make
	make install
fi

#Clone the repo
cd /opt/
git clone $REPO
cd $NAME
git checkout $VERSION
mv bin/heartbeatProbes.py bin/wiotp-heartbeat-probes

#Patch
sed -i "s#ibm_db==3.0.4#ibm_db==3.1.0#g" setup.py

#Build and test
export W3_USERNAME
export W3_PASSWORD
tox

#ERROR: InvocationError for command /opt/wiotp-utils-py/.tox/py36/bin/pytest (exited with code 5)
#The above error indicates "Build Successful. No tests were found."
