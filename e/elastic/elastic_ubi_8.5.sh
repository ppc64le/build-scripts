# -----------------------------------------------------------------------------
#
# Package	: github.com/olivere/elastic/v7
# Version	: v7.0.22
# Source repo	: https://github.com/olivere/elastic
# Tested on	: UBI 8.5
# Language      : GO
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Run as:	  docker run -it --network host -v /var/run/docker.sock:/var/run/docker.sock registry.access.redhat.com/ubi8
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/olivere/elastic/v7
PACKAGE_VERSION=${1:-v7.0.22}

yum install -y git golang nc wget

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Install Docker binary
wget https://download.docker.com/linux/static/stable/ppc64le/docker-18.06.3-ce.tgz
tar -xf docker-18.06.3-ce.tgz
mv ./docker/docker /usr/local/bin
chmod +x /usr/local/bin/docker

# Create Elasticsearch container at Port 9200
docker run -d \
	--name elasticsearch \
	--ulimit nproc=65536 \
	--ulimit nofile=65536:65536 \
	--ulimit memlock=-1:-1 \
	-p 9200:9200 \
	-e cluster.name=elasticsearch \
	-e bootstrap.memory_lock=true \
	-e discovery.type=single-node \
	-e network.publish_host=127.0.0.1 \
	-e logger.org.elasticsearch=warn \
	-e "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
	ibmcom/elasticsearch-ppc64le:v7.9.1

# Create Elasticsearch container at Port 9210
docker run -d \
	--name elasticsearch-platinum \
	--ulimit nproc=65536 \
	--ulimit nofile=65536:65536 \
	--ulimit memlock=-1:-1 \
	-p 9210:9210 \
	-e cluster.name=platinum \
	-e bootstrap.memory_lock=true \
	-e discovery.type=single-node \
	-e xpack.license.self_generated.type=trial \
	-e xpack.security.enabled=true \
	-e xpack.watcher.enabled=true \
	-e http.port=9210 \
	-e network.publish_host=127.0.0.1 \
	-e logger.org.elasticsearch=warn \
	-e "ES_JAVA_OPTS=-Xms1g -Xmx1g" \
	-e ELASTIC_PASSWORD=elastic \
	ibmcom/elasticsearch-ppc64le:v7.9.1

# Wait for Elasticsearch to start up
sleep 10
while ! nc -z localhost 9200; do sleep 1; done
while ! nc -z localhost 9210; do sleep 1; done

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd ~/go/pkg/mod/$PACKAGE_NAME*
if ! go mod tidy; then
	echo "------------------$PACKAGE_NAME:dependency_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Dependency_Fails"
	exit 1
fi

cd ~/go/pkg/mod/$PACKAGE_NAME*
if ! go test -timeout 30m -deprecations -strict-decoder -v . ./aws/... ./config/... ./trace/... ./uritemplates/...; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_and_Test_Success"
	exit 0
fi
