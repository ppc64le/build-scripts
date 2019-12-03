# ----------------------------------------------------------------------------
#
# Package       : Hue
# Version       : 4.5.0
# Source repo   : https://github.com/cloudera/hue/
# Tested on     : rhel_7.6
# Script License: Apache License, Version 2
# Maintainer    : Amol Patil <amol.patil2p@ibm.com>
#
# ----------------------------------------------------------------------------

#!/bin/bash

HUE_VERSION=4.5.0

#Install dependencies
yum update -y
yum install -y git make curl python27.ppc64le java-1.8.0-openjdk java-1.8.0-openjdk-devel \
        ant asciidoc cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain gcc gcc-c++ krb5-devel libffi-devel \
        libxml2-devel libxslt-devel  mysql mysql-devel openldap-devel python-devel sqlite-devel gmp-devel

yum install -y maven libtidy openssl-devel.ppc64le

curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash
source ~/.nvm/nvm.sh
nvm install v8.9.4

git clone https://github.com/cloudera/hue.git
cd hue && git checkout branch-$HUE_VERSION

make apps
build/env/bin/hue runserver
