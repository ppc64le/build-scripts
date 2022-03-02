# -----------------------------------------------------------------------------
#
# Package	: docile
# Version	: v1.4.0
# Source repo	: https://github.com/ms-ati/docile
# Tested on	: UBI 8.4
# Language      : Ruby
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {Sapana.khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 

PACKAGE_NAME=docile
PACKAGE_VERSION=v1.4.0
PACKAGE_URL=https://github.com/ms-ati/docile.git

yum install -y nodejs nodejs-devel nodejs-packaging git wget curl ruby ruby-devel rubygem-rake procps libcurl-devel libffi-devel sqlite sqlite-devel

yum install -y --allowerasing gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget

yum-config-manager --add-repo http://mirror.centos.org/centos/8/AppStream/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/PowerTools/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/virt/ppc64le/ovirt-44/

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization && mv RPM-GPG-KEY-CentOS-SIG-Virtualization /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization

#yum install -y libsodium-devel libicu-devel libicu langtable

gem install bundle
gem install rake
gem install kramdown-parser-gfm
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable
export PATH=$PATH:/usr/local/rvm/bin

/bin/bash -c "source /etc/profile.d/rvm.sh; rvm install ruby-2.7;"

mkdir -p /home/tester/output
cd /home/tester
export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

source /etc/profile.d/rvm.sh;

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

bundle install

bundle exec rspec

exit 0
