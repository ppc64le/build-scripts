# ----------------------------------------------------------------------------
#
# Package	: andreas-hess_webcrawler
# Version	: Not available.
# Source repo	: http://andreas-hess.info/programming/webcrawler
# Tested on	: rhel_7.2
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
sudo yum install -y wget java-1.7.0-openjdk java-1.7.0-openjdk-devel zip unzip
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Obtain source.
WORKDIR=$HOME
cd $WORKDIR
wget http://andreas-hess.info/programming/webcrawler/multiweb.zip && unzip multiweb.zip -d multiweb
cd $WORKDIR/multiweb
mkdir classes
javac -d ./classes ie/moguntia/threads/*.java
javac -d ./classes -cp ./classes ie/moguntia/webcrawler/*.java
export CLASSPATH=$WORKDIR/multiweb/classes

# Test the webcrawler.
java -cp ./classes ie.moguntia.webcrawler.WSDLCrawler https://www.google.co.in/ abc
