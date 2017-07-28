#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : tiff
# Version       : 4.0.6 
# Source repo   : http://download.osgeo.org/libtiff/           
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
sudo yum install xz-libs-5.2.2-1.el7.ppc64le -y
sudo yum install libjpeg-turbo-1.2.90-5.el7.ppc64le -y
sudo yum install zlib-1.2.7-17.el7.ppc64le -y
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install freeglut-2.8.1-3.el7.ppc64le -y
sudo yum install libSM-1.2.2-2.el7.ppc64le -y
sudo yum install libICE-1.0.9-2.el7.ppc64le -y
sudo yum install libXi-1.7.4-2.el7.ppc64le -y
sudo yum install mesa-libGLU-9.0.0-4.el7.ppc64le -y
sudo yum install mesa-libGL-11.2.2-2.20160614.el7.ppc64le -y
sudo yum install libXext-1.3.3-3.el7.ppc64le -y
sudo yum install libX11-1.6.3-3.el7.ppc64le -y
sudo yum install libXxf86vm-1.1.3-2.1.el7.ppc64le -y
sudo yum install libuuid-2.23.2-33.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y
sudo yum install expat-2.1.0-8.el7.ppc64le -y
sudo yum install libxcb-1.11-4.el7.ppc64le -y
sudo yum install libxshmfence-1.2-1.el7.ppc64le -y
sudo yum install mesa-libglapi-11.2.2-2.20160614.el7.ppc64le -y
sudo yum install libselinux-2.5-6.el7.ppc64le -y
sudo yum install libXdamage-1.1.4-4.1.el7.ppc64le -y
sudo yum install libXfixes-5.0.1-2.1.el7.ppc64le -y
sudo yum install libdrm-2.4.67-3.el7.ppc64le -y
sudo yum install pcre-8.32-15.el7_2.1.ppc64le -y
sudo yum install libXau-1.0.8-2.1.el7.ppc64le -y

# download and unpack
wget http://download.osgeo.org/libtiff/tiff-4.0.6.tar.gz
tar -xzvf tiff-4.0.6.tar.gz
cd tiff-4.0.6

# make
./configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info --with-bugurl=http://bugzilla.redhat.com/bugzilla --enable-bootstrap --enable-shared --enable-threads=posix --enable-checking=release --with-system-zlib --enable-__cxa_atexit --disable-libunwind-exceptions --enable-gnu-unique-object --enable-linker-build-id --with-linker-hash-style=gnu --enable-languages=c,c++,objc,obj-c++,java,fortran,go,lto --enable-plugin --enable-initfini-array --disable-libgcj --with-isl=/builddir/build/BUILD/gcc-4.8.5-20150702/obj-ppc64le-redhat-linux/isl-install --with-cloog=/builddir/build/BUILD/gcc-4.8.5-20150702/obj-ppc64le-redhat-linux/cloog-install --enable-gnu-indirect-function --enable-secureplt --with-long-double-128 --enable-targets=powerpcle-linux --disable-multilib --with-cpu-64=power7 --with-tune-64=power8 --build=ppc64le-redhat-linux 
make
sudo make install
