# ----------------------------------------------------------------------------
#
# Package	: libtld
# Version	: 1.5.0
# Source repo	: http://sourceforge.net/projects/libtld
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies.
sudo yum update -y
sudo yum install -y wget tar gcc gcc-c++ make cmake boost-devel \
    qt-devel doxygen graphviz graphviz-dev

# Get the source.
wget http://sourceforge.net/projects/libtld/files/libtld_1.5.0.tar.gz
tar xzf libtld_1.5.0.tar.gz
wget http://sourceforge.net/projects/libtld/files/libtld-doc-1.5.tar.gz
tar xzf libtld-doc-1.5.tar.gz
wget http://sourceforge.net/projects/libtld/files/snapcmakemodules_1.0.24.53.tar.gz
tar xzf snapcmakemodules_1.0.24.53.tar.gz
mkdir BUILD
cd BUILD
cmake -DCMAKE_MODULE_PATH=../snapCMakeModules/Modules ../libtld
make
sudo make install

# Run a basic test.
cd src
./validate_tld http://snapwebsites.org/project/libtld
if [ $? -eq 0 ] ; then
  echo "success"
fi
