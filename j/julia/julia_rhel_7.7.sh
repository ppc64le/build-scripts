# ----------------------------------------------------------------------------
#
# Package	: julia
# Version	: v1.3.1
# Source repo	: 
# Tested on	: RHEL 7.7
# Script License: Apache License Version 2.0
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
#Install required dependencies
sudo yum update -y
sudo yum install wget expat-devel openssl-devel libcurl-devel tk gettext-devel make gcc gcc-c++ patch bzip2 m4

WORKDIR=$HOME/Julia
mkdir -p $WORKDIR

#Build git2 from source	
cd $WORKDIR
wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.25.1.tar.gz
tar -zxvf git-2.25.1.tar.gz
cd git-2.25.1
make
sudo make install
export PATH=$HOME/bin:$PATH

#Build cmake from source
cd $WORKDIR
wget https://cmake.org/files/v3.11/cmake-3.11.4.tar.gz
tar -zxvf cmake-3.11.4.tar.gz
cd cmake-3.11.4
./bootstrap --system-curl
make
sudo make install
export PATH=/usr/local/bin:$PATH

#Install AT 11.0
cd $WORKDIR
# https://developer.ibm.com/linuxonpower/advance-toolchain/advtool-installation/
wget ftp://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL7/gpg-pubkey-6976a827-5164221b
sudo rpm --import gpg-pubkey-6976a827-5164221b

echo '# Begin of configuration file
[advance-toolchain]
name=Advance Toolchain IBM FTP
baseurl=ftp://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL7
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=ftp://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL7/gpg-pubkey-6976a827-5164221b
# End of configuration file' > /etc/yum.repos.d/advance-toolchain.repo

sudo yum update

sudo yum install advance-toolchain-at11.0-runtime \
    advance-toolchain-at11.0-devel \
    advance-toolchain-at11.0-perf

cd $WORKDIR
git clone https://github.com/JuliaLang/julia
cd julia
git checkout v1.3.1
PATH=/opt/at11.0/bin:/opt/at11.0/sbin:$PATH make O=$WORKDIR/builds/julia configure
cd $WORKDIR/builds/julia
cat <<EOF > Make.user
USE_BINARYBUILDER=0
EOF
PATH=/opt/at11.0/bin:/opt/at11.0/sbin:$PATH make -j

#Basic manual tests as per https://juliabyexample.helpmanual.io/ pass
#However, unit test cases still need some work on Power
#PATH=/opt/at11.0/bin:/opt/at11.0/sbin:$PATH  make test
