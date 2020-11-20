# ----------------------------------------------------------------------------
#
# Package       : qpid-proton
# Version       : 0.30.0
# Source repo   : https://github.com/apache/qpid-proton
# Tested on     : UBI 8.2
# Script License: Apache License Version 2.0
# Maintainer    : Priya Seth<sethp@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Version of qpid-proton to be built
if [ $# -eq 1 ]; then
    VERSION=$1
else
    VERSION=0.30.0
fi

sudo dnf -y update

# Required dependencies
sudo dnf -y install gcc gcc-c++ make cmake libuuid-devel git

# Dependencies needed for SSL support
sudo dnf -y install openssl-devel

# Dependencies needed for Cyrus SASL support
sudo dnf -y install cyrus-sasl-devel cyrus-sasl-plain
sudo dnf -y install https://rpmfind.net/linux/centos/8.1.1911/BaseOS/ppc64le/os/Packages/cyrus-sasl-md5-2.1.27-1.el8.ppc64le.rpm

# Dependencies needed for bindings
sudo dnf -y install https://rpmfind.net/linux/fedora-secondary/releases/32/Everything/ppc64le/os/Packages/s/swig-4.0.1-7.fc32.ppc64le.rpm
sudo dnf -y install python36-devel
sudo dnf -y install ruby-devel rubygem-minitest

sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf -y install jsoncpp-devel

#Build from source
git clone https://github.com/apache/qpid-proton --branch=${VERSION}
cd qpid-proton
mkdir build
cd build

# Set the install prefix. You may need to adjust it depending on your
# system.
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DSYSINSTALL_BINDINGS=ON

make all
# make test

# Note that this step will require root privileges.
sudo make install
