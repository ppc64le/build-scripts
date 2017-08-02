# ----------------------------------------------------------------------------
#
# Package	: rust-prometheus
# Version	: 0.2
# Source repo	: https://github.com/pingcap/rust-prometheus.git
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
sudo yum install -y wget git gcc

# Install rust.
wget https://static.rust-lang.org/dist/rust-nightly-powerpc64le-unknown-linux-gnu.tar.gz
tar -zxvf rust-nightly-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-nightly-powerpc64le-unknown-linux-gnu
sudo sh install.sh
rm -rf rust-nightly-powerpc64le-unknown-linux-gnu.tar.gz
rm -rf rust-nightly-powerpc64le-unknown-linux-gnu

# Clone and build source code.
git clone https://github.com/pingcap/rust-prometheus.git
cd rust-prometheus
cargo build
cargo test
