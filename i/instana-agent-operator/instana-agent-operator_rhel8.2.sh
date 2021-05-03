# ----------------------------------------------------------------------------
#
# Package        : instana-agent-operator
# Version        : v1.0.4
# Source repo    : https://github.com/instana/instana-agent-operator.git
# Tested on      : RHEL 8.2
# Script License : Apache License, Version 2 or later
# Maintainer     : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -eu

CWD=`pwd`

CLUSTER_NAME=instana-demo
PACKAGE_VERSION=v1.0.4

usage() {
    echo "Usage: ./<script> -k <AGENT_KEY> [-n <CLUSTER_NAME>] [-v <PACKAGE_VERSION>]"
    echo "where, CLUSTER_NAME is an optional paramater whose default value is instana-demo"
    echo "       PACKAGE_VERSION is an optional paramater whose default value is v1.0.4"
}

while getopts ":k:n:v:" opt; do
    case $opt in
        k) AGENT_KEY="$OPTARG"
        ;;
        n) CLUSTER_NAME="$OPTARG"
        ;;
        v) PACKAGE_VERSION="$OPTARG"
        ;;
        \?) usage
            exit 1
        ;;
    esac
done

if [ -z ${AGENT_KEY+x} ]; then
    usage
    exit 1
fi

# Install dependencies
yum install -y java-11-openjdk-devel wget git

# Download and install maven
wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz
rm -rf apache-maven-3.6.3-bin.tar.gz

# Set enviroment variables
export MAVEN_HOME=$CWD/apache-maven-3.6.3
JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JAVA_HOME=${JDK_PATHS%$'\n'*}
export PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH

# Clone the repo, run build+tests and build image
git clone https://github.com/instana/instana-agent-operator.git
cd instana-agent-operator/
git checkout $PACKAGE_VERSION
sed -i '/agent.zone.name: my-zone/d' deploy/instana-agent.customresource.yaml
sed -i 's/agent.key: replace-me/agent.key: '"${AGENT_KEY}"'/g' deploy/instana-agent.customresource.yaml
sed -i 's/cluster.name: replace-me/cluster.name: '"${CLUSTER_NAME}"'/g' deploy/instana-agent.customresource.yaml
sed -i -e '/# replace with your Instana agent key/a\  agent.imagePullPolicy: IfNotPresent' deploy/instana-agent.customresource.yaml
sed -i 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' olm/operator-resources/instana-agent-operator.yaml
sed -i 's/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g' src/main/resources/instana-agent.daemonset.yaml
./mvnw -C -B clean verify
docker build -f src/main/docker/Dockerfile.jvm -t instana/instana-agent-operator .

echo "Build, test execution and image creation successful!"
