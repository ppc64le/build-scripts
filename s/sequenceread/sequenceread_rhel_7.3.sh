#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : sequenceread  
# Version       : 2.1.14 
# Source repo   : https://sourceforge.net/projects/sequenceread/files/sequenceread/2.1.4/         
# Tested on     : rhel_7.3 
# Script License: Apache License, Version 2 or later
# Maintainer    : Shane Barrantes <shane.barrantes@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintaine" of this script.
#
# ---------------------------------------------------------------------------- 

working_dir=`pwd`

# Update Source
sudo yum update -y

# gcc dev tools
sudo yum groupinstall 'Development Tools' -y

# install dependencies
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install xz-libs-5.2.2-1.el7.ppc64le -y
sudo yum install bzip2-libs-1.0.6-13.el7.ppc64le -y
sudo yum install libcurl-7.29.0-35.el7.ppc64le -y
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install libidn-1.28-4.el7.ppc64le -y
sudo yum install libssh2-1.4.3-10.el7_2.1.ppc64le -y
sudo yum install nss-3.21.0-17.el7.ppc64le -y
sudo yum install nspr-4.11.0-1.el7_2.ppc64le -y
sudo yum install libcom_err-1.42.9-9.el7.ppc64le -y
sudo yum install openldap-2.4.40-13.el7.ppc64le -y
sudo yum install openssl-libs-1.0.1e-60.el7.ppc64le -y
sudo yum install keyutils-libs-1.5.8-3.el7.ppc64le -y
sudo yum install cyrus-sasl-lib-2.1.26-20.el7_2.ppc64le -y
sudo yum install libselinux-2.5-6.el7.ppc64le -y
sudo yum install pcre-8.32-15.el7_2.1.ppc64le -y
sudo yum install nss-softokn-freebl-3.16.2.3-14.4.el7.ppc64le -y
sudo yum install bzip2-libs-1.0.6-13.el7.ppc64le -y
sudo yum install keyutils-libs-1.5.8-3.el7.ppc64le -y

#download and unpack source code
wget https://sourceforge.net/projects/staden/files/io_lib/1.14.8/io_lib-1.14.8.tar.gz
tar -xzvf io_lib-1.14.8.tar.gz

#configure, make, make install
cd io_lib-1.14.8
sudo ./configure ; sudo make ; sudo make install
cd $working_dir

# download and unpack
wget https://sourceforge.net/projects/sequenceread/files/sequenceread/2.1.4/sequenceread-2.1.4.tar.gz
tar -xzvf sequenceread-2.1.4.tar.gz
cd sequenceread-2.1.4

# make
./configure --build=ppc64le
make
sudo make install
