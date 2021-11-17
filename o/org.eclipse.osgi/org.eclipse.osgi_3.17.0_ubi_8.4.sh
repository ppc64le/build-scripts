# ----------------------------------------------------------------------------------------------------
#
# Package       : org.eclipse.osgi
# Version       : 3.17.0
# Tested on     : UBI 8.4 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Atharv Phadnis <Atharv.Phadnis@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------
#!/bin/bash

set -ex

#install dependencies
yum install -y wget git java-11-openjdk-devel
cd /opt
wget https://archive.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
tar xzvf apache-maven-3.8.1-bin.tar.gz
export PATH=/opt/apache-maven-3.8.1/bin:$PATH


#get sources
git clone https://git.eclipse.org/r/equinox/rt.equinox.framework.git
git clone https://git.eclipse.org/r/equinox/rt.equinox.binaries.git
cd rt.equinox.framework
git checkout R4_21

# Add ppc64le to manifest
sed -i '/processor=ppc64;/i \ processor=ppc64le;' bundles/org.eclipse.osgi.tests/bundles_src/nativetest.a1/META-INF/MANIFEST.MF
sed -i '/processor=ppc64;/i \ processor=ppc64le;' bundles/org.eclipse.osgi.tests/bundles_src/nativetest.a2/META-INF/MANIFEST.MF
sed -i '/processor=ppc64;/i \ processor=ppc64le;' bundles/org.eclipse.osgi.tests/bundles_src/nativetest.b1/META-INF/MANIFEST.MF
sed -i '/processor=ppc64;/i \ processor=ppc64le;' bundles/org.eclipse.osgi.tests/bundles_src/nativetest.b2/META-INF/MANIFEST.MF

# build and test
mvn -Pbuild-individual-bundles clean verify

#conclude
set +ex
find -name org.eclipse.osgi-*.jar
echo "Complete!"