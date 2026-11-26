#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: luajit2
# Version	: v2.1-agentzh
# Source repo	: https://github.com/openresty/luajit2
# Tested on	: UBI 8.5
# Language      : C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vaibhav Bhadade <vaibhav.bhadade@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=luajit2
PACKAGE_VERSION=v2.1-agentzh
PACKAGE_URL=https://github.com/v2.1-agentzh

TEST_RUN=0
yum update -y
yum install -y git wget
dnf install libmpc-devel gtk2-devel mpfr-devel gcc gcc-c++ valgrind perl-Parallel-ForkManager 

# Install luajit

git clone https://github.com/openresty/luajit2.git
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
patch src/vm_ppc.dasc ../luajit_vm_ppc.patch

make
make install

# Build & Test
if [$TEST_RUN==1] then
	cd ../
	git clone https://github.com/openresty/luajit2-test-suite.git
	cd luajit2-test-suite 
	./run-tests /usr/local/openresty/luajit
fi
	
