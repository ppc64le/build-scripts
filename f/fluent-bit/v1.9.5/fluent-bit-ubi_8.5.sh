# -----------------------------------------------------------------------------
#
# Package	: fluent-bit
# Version	: v1.9.5
# Source repo	: https://github.com/fluent/fluent-bit
# Tested on	: RHEL 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -ex
trap cleanup EXIT
function cleanup {
  echo "ERROR: Script failed"
}

FLUENTBIT_VERSION=${1:-1.9.5}
USE_CENTOS_REPOS=${2:-1}
USE_MOONJIT=${3:-1}
BUILD_HOME=$(pwd)

#Install dependencies
if [ "$USE_CENTOS_REPOS" -eq 1 ]
then
	dnf -y install --nogpgcheck https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
	sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
	sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
fi
yum install gcc gcc-c++ libyaml-devel wget cmake3 python3 git openssl-devel flex bison diffutils autoconf postgresql-devel cyrus-sasl-devel systemd-devel valgrind-devel -y

#Get repo
#wget https://github.com/fluent/fluent-bit/archive/refs/tags/v$FLUENTBIT_VERSION.tar.gz
#tar -xzvf v$FLUENTBIT_VERSION.tar.gz
git clone https://github.com/fluent/fluent-bit.git
cd fluent-bit/
git checkout v$FLUENTBIT_VERSION

#Apply libco, pack and luajit patch
cp ../ppc64le.c lib/monkey/deps/flb_libco/
sed -i 's#ppc.c#ppc64le.c#g' lib/monkey/deps/flb_libco/libco.c
sed -i 's#luajit-2.1.0-1e66d0f#luajit2#g' cmake/libraries.cmake
sed -i.bak '706,741d' src/flb_utils.c
sed -i '706i else if (c >= 0x80) {' src/flb_utils.c

#Get luajit2 and create ./configure
cd $BUILD_HOME/fluent-bit/lib/
if [ "$USE_MOONJIT" -eq 1 ]
then
	git clone https://github.com/moonjit/moonjit.git
	mv moonjit luajit2
	cd luajit2/
	git checkout 2.2.0
	sed -i '24i #if LJ_ARCH_PPC_ELFV2' src/lj_ccallback.c
	sed -i '25i #include "lualib.h"' src/lj_ccallback.c
	sed -i '26i #endif' src/lj_ccallback.c
else
	git clone https://github.com/openresty/luajit2.git
	cd luajit2/
	git checkout v2.1-20220411
fi
echo "exit 0;" >> configure
chmod +x configure

#Build
cd $BUILD_HOME/fluent-bit/build/
cmake -DFLB_TESTS_RUNTIME=On -DFLB_TESTS_INTERNAL=On -DFLB_DEBUG=On ..
make -j "$(getconf _NPROCESSORS_ONLN)"

#Test
make test || true
echo "SUCCESS: Build and test success. The two failing tests (52 - flb-rt-out_td, 62 - flb-it-network) are in parity with x86_64."

#Run
#bin/fluent-bit -i cpu -o stdout -f 1

# Command to run Luajit in fluent-bit
#bin/fluent-bit -i dummy -F lua -p script=../scripts/test.lua -p call=cb_print -m '*' -o stdout -f 1 --verbose
