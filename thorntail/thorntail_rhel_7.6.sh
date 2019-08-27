# ----------------------------------------------------------------------------
#
# Package	: Thorntail
# Version	: latest
# Source repo	: https://github.com/thorntail/thorntail.git
# Tested on	: rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer	: Vrushali Inamdar <vrushali.inamdar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

wrkdir=`pwd`

# Build PhantomJS binary file from source code on Power
#yum -y update
yum -y install gcc gcc-c++ make flex bison gperftools-libs \
    ruby openssl-devel freetype-devel fontconfig-devel libicu-devel \
    sqlite-devel libpng-devel libjpeg-devel wget git tar gzip bzip2 libwebp-devel

echo "Installing gperf"
wget http://ftp.gnu.org/pub/gnu/gperf/gperf-3.0.4.tar.gz
tar -xzf gperf-3.0.4.tar.gz
cd $wrkdir/gperf-3.0.4 && ./configure && make && make install

# Clone PhantomJS code and build it.
cd $wrkdir
git clone git://github.com/ariya/phantomjs.git
cd $wrkdir/phantomjs && git checkout 2.1.1 && \
   git submodule init && git submodule update && ./build.py -c
echo "# # # phantomjs build completed."

# # Save the path to PhantomJS binary
phantomjs_binary_path=$wrkdir/phantomjs/bin
echo "# # #$phantomjs_binary_path"

## Clone Thorntail source code from Git and build it

cd $wrkdir
git clone https://github.com/thorntail/thorntail.git
cd $wrkdir/thorntail

grep -rnwl '.' -e '<extension qualifier="webdriver">' | while read -r filename ; do

    echo "Modifying $filename ... "

    # Find the text in the file and append 'phantomjs.binary.path' property to it
	# create a back-up in .bkp file before this modification
    sed -i.bkp  "/<extension qualifier=\"webdriver\">/a <property name=\"phantomjs.binary.path\">\\$phantomjs_binary_path/phantomjs</property>" $filename 	
	echo "Done"
done 

# Build thorntail
mvn clean install --log-file ./thorntail-build.log

echo "# # # Thorntail build completed. Please check the build status in thorntail/thorntail-build.log file."
