#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package           : Odoo
# Version           : 16.0
# Source repo       : https://github.com/odoo/odoo
# Tested on         : UBI: 8.5
# Language          : Python
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=odoo
PACKAGE_URL=https://github.com/odoo/odoo
PACKAGE_VERSION=${1:-16.0}

yum install -y wget git yum-utils openldap-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libjpeg-devel openssl openssl-devel postgresql-devel gcc gcc-c++ libicu lz4 make bzip2-devel zlib-devel 

# Install Python 3.10
wget https://www.python.org/ftp/python/3.10.8/Python-3.10.8.tgz 
tar xzf Python-3.10.8.tgz 
cd Python-3.10.8 
./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions 
make -j ${nproc}
make altinstall
export PATH=$PATH:/usr/local/bin
cd .. && rm Python-3.10.8.tgz 

# Install Rust
cd ..
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# Activate venv
python3.10 -m venv odoo-venv
. ./odoo-venv/bin/activate

# Clone Odoo
rm -rf odoo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install dependencies
python3.10 -m pip install pip wheel
python3.10 -m pip install -r requirements.txt

# Run test suite, refer README
python3.10 odoo-bin -d mydb -r user1 -w pass --db_host 172.21.0.2 --db_port 5432 -i base --stop-after-init --log-level=test --max-cron-threads=0

# Start Odoo server, refer README
# python3.10 odoo-bin -d mydb -r odoo -w odoo --db_host 172.21.0.2 --db_port 5432 -i INIT