#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : plr
# Version       : REL8_4
# Source repo   : https://github.com/postgres-plr/plr.git
# Tested on     : UBI 8.5
# Language      : C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vikas Kumar <kumar.vikas@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=plr
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-REL8_4}
PACKAGE_URL=https://github.com/postgres-plr/plr.git

cat > /etc/yum.repos.d/centos.repo<<EOF
[local-rhn-server-baseos]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server RPMs
baseurl=http://mirror.centos.org/centos/8-stream/BaseOS/\$basearch/os/
enabled=1
gpgcheck=0
[local-rhn-server-appstream]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server Supplementary RPMs
baseurl=http://mirror.centos.org/centos/8-stream/AppStream/\$basearch/os/
enabled=1
gpgcheck=0
[local-rhn-server-powertools]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server Supplementary RPMs
baseurl=http://mirror.centos.org/centos/8-stream/PowerTools/\$basearch/os/
enabled=1
gpgcheck=0
EOF

yum group install -y 'Development Tools'
yum install -y readline-devel

# Build and install postgresql to build and test plr package
git clone --depth=2 -b REL_11_15 https://github.com/postgres/postgres
cd postgres
./configure
make
make install

adduser postgres
mkdir /usr/local/pgsql/data
chown postgres:postgres /usr/local/pgsql/data

runuser -l postgres -c '/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data/'
runuser -l postgres -c '/usr/local/pgsql/bin/postmaster -D /usr/local/pgsql/data >logfile 2>&1' &

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y R
export USE_PGXS=1
export PATH=/usr/local/pgsql/bin:$PATH

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 0
fi

cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! SHLIB_LINK=-lgcov PG_CPPFLAGS="-fprofile-arcs -ftest-coverage -O0" make; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! make install; then
    echo "------------------$PACKAGE_NAME:build_success_but_insall_fails------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Success_But_Install_Fails"
	exit 1
fi

if ! make installcheck PGUSER=postgres || (cat regression.diffs && false); then
	echo "------------------$PACKAGE_NAME:build_and_install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_And_Install_Success_But_Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:build_install_&_test_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Install_and_Test_Success"
	exit 0
fi
