#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : pandaseq
# Version       : 2.10  
# Source repo   : https://github.com/neufeld/pandaseq/releases      
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

# Update Source
sudo yum update -y

# gcc dev tools
sudo yum groupinstall 'Development Tools' -y

# install dependencies
sudo yum install bzip2-libs-1.0.6-13.el7.ppc64le -y 
sudo yum install glibc-2.17-157.el7.ppc64le -y 
sudo yum install libtool-ltdl-2.4.2-21.el7_2.ppc64le -y 
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install libtool-ltdl-devel -y

# download and unpack
git clone https://github.com/neufeld/pandaseq.git
cd pandaseq

# make
./autogen.sh && ./configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info --with-bugurl=http://bugzilla.redhat.com/bugzilla --enable-bootstrap --enable-shared --enable-threads=posix --enable-checking=release --with-system-zlib --enable-__cxa_atexit --disable-libunwind-exceptions --enable-gnu-unique-object --enable-linker-build-id --with-linker-hash-style=gnu --enable-languages=c,c++,objc,obj-c++,java,fortran,go,lto --enable-plugin --enable-initfini-array --disable-libgcj --with-isl=/builddir/build/BUILD/gcc-4.8.5-20150702/obj-ppc64le-redhat-linux/isl-install --with-cloog=/builddir/build/BUILD/gcc-4.8.5-20150702/obj-ppc64le-redhat-linux/cloog-install --enable-gnu-indirect-function --enable-secureplt --with-long-double-128 --enable-targets=powerpcle-linux --disable-multilib --with-cpu-64=power7 --with-tune-64=power8 --build=ppc64le-redhat-linux  && make && sudo make install
