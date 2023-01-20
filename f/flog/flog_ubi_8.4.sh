#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: flog
# Version	: 4.6.2
# Source repo	: https://github.com/seattlerb/flog
# Tested on	: UBI 8.4
# Language      : Ruby
# Travis-Check  : True
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

PACKAGE_NAME=flog
PACKAGE_VERSION=${1:-v4.6.2}
PACKAGE_URL=https://github.com/seattlerb/flog

yum install -y git wget curl ruby ruby-devel rubygem-rake procps libcurl-devel libffi-devel sqlite sqlite-devel 


yum config-manager --add-repo http://vault.centos.org/centos/8/AppStream/ppc64le/os/ && yum config-manager --add-repo http://vault.centos.org/centos/8/BaseOS/ppc64le/os/

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization && mv RPM-GPG-KEY-CentOS-SIG-Virtualization /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization

gem install bundle
gem install rake
gem install kramdown-parser-gfm
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable
export PATH=$PATH:/usr/local/rvm/bin

/bin/bash -c "source /etc/profile.d/rvm.sh; rvm install ruby-2.7;"
export PATH="/usr/local/rvm/rubies/ruby-2.7.2/bin:$PATH"

mkdir -p /home/tester/output
cd /home/tester

export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

source /etc/profile.d/rvm.sh;

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

gem install hoe
gem install sexp_processor
gem install path_expander
gem install ruby_parser

rake

exit 0
