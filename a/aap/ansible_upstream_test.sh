# ----------------------------------------------------------------------------
#
# Package        : ansible
# Version        : ansible [core 2.14.2]
# Source repo    : https://github.com/ansible/ansible-rulebook.git
# Tested on      : RHEL8.7/RHEL9.1
# Script License : Apache License, Version 2 or later
# Maintainer     : Ashwini Kadam <Ashwini.Kadam@ibm.com>
#
# Disclaimer: This script has been tested in root  mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

echo "started package installation for upstream repo"
yum install java-17-openjdk-devel openssl-devel git wget tar python39-devel.ppc64le gcc rust cargo  gcc-c++ cmake.ppc64le -y
java -version 

wget https://dlcdn.apache.org/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
tar -xzvf apache-maven-3.8.7-bin.tar.gz -C /opt/
ln -s /opt/apache-maven-3.8.7/bin/mvn /usr/local/bin/mvn
rm -f apache-maven-3.8.7-bin.tar.gz

git clone https://github.com/ansible/ansible-rulebook.git
cd ansible-rulebook

echo "Inside ansible-rulebook $pwd"
export JDK_HOME=/usr/lib/jvm/java-17-openjdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

pip3 install -r requirements_test.txt
pip3 install .
ansible-galaxy collection install git+https://github.com/ansible/event-driven-ansible
pip3 install pyparsing jsonschema websockets drools-jpy
pytest -v -n auto
echo "Completed ansible-rulebook Test suite"

cd ../
git clone https://github.com/ansible/event-driven-ansible.git
cd event-driven-ansible
pip3 install kafka asyncmock aiokafka boto3 aiobotocore azure-storage-blob azure-identity azure-servicebus
pytest
echo "Completed ansible-eda Test suite"
