#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package   : dotnet
# Version   : 7.0
# Source repo   : https://github.com/dotnet/runtime
# Tested on : Ubuntu-1804
# Language      : C, C#
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Sapana.Khemkar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#1. Install prerequisites.
#./prereq_install

#2. Prepare setup (Clone various repos + apply patches)
# TO DO: use raw github url (Eg. wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/elasticsearch/elasticsearch_v7.17.2.patch)
#wget <github raw url for build-script>
./dotnet-prepare-ppc64le

#3. Build the tar
./dotnet-build-ppc64le
