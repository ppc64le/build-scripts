# ----------------------------------------------------------------------------
#
# Package	: logstash-forwarder
# Version	: 0.4.0
# Source repo	: https://github.com/elastic/logstash-forwarder.git
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
sudo yum update -y
sudo yum install --nogpgcheck -y libgo.ppc64le ruby-devel git ruby \
  gcc make gem ruby-devel libffi-devel libgo-devel.ppc64le \
  libgo-static.ppc64le gem gcc-go.ppc64le

# Install Advance Toolchain
sudo touch /etc/yum.repos.d/advance_9.0.repo
sudo chmod 777 /etc/yum.repos.d/advance_9.0.repo
cat > /etc/yum.repos.d/advance_9.0.repo << EOF

[at9.0]
name=Advance Toolchain Unicamp FTP
baseurl=ftp://ftp.unicamp.br/pub/linuxpatch/toolchain/at/redhat/RHEL7
failovermethod=priority
enabled=1
gpgcheck=0

EOF

sudo yum clean all
sudo yum repolist

sudo yum install -y git which find gcc \
    advance-toolchain-at9.0-runtime-9.0-1.ppc64le \
    advance-toolchain-at9.0-devel-9.0-1.ppc64le \
    advance-toolchain-at9.0-mcore-libs-9.0-1.ppc64le \
    advance-toolchain-at9.0-perf-9.0-1.ppc64le

# Build GOLANG from source for Redhat 7.2 on PPC64[LE]. Run as root.
# Get/update source code, check out the latest tag, and build

git clone https://go.googlesource.com/go
cd go
git checkout tags/go1.6.1
cd src
export GOROOT_BOOTSTRAP=$(/opt/at9.0/bin/go env GOROOT)
./make.bash
cd ..
virtual_root=`pwd`

export GOROOT=$virtual_root
export PATH=$PATH:$virtual_root/bin

cd
git clone https://github.com/elastic/logstash-forwarder.git
cd logstash-forwarder
go build -gccgoflags '-static-libgo' -o logstash-forwarder
