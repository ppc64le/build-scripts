# ----------------------------------------------------------------------------
# Package       : websocat
# Version       : commit #a000784
# Source repo   : https://github.com/vi/websocat.git
# Tested on     : UBI 8.2
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
dnf -y --disableplugin=subscription-manager install \
    http://mirror.centos.org/centos/8.2.2004/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8.2-2.2004.0.2.el8.noarch.rpm \
    http://mirror.centos.org/centos/8.2.2004/BaseOS/ppc64le/os/Packages/centos-repos-8.2-2.2004.0.2.el8.ppc64le.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

yum install rust cargo openssl-devel git -y

# Clone and build source.
git clone https://github.com/vi/websocat.git
git checkout a00078416e3f94a32d385dbd24538c6fffda86f3
cd websocat
cargo build --release --features=ssl
sed -i 's/PATH=target\/debug/PATH=target\/release/g' test.sh
./test.sh
