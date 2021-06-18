# Package 	: graylog2-server
# Version 	: master
# Source repo 	: https://github.com/Graylog2/graylog2-server.git
# Tested on 	: rhel_8.3
# Maintainer 	: maniraj.deivendran@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# --------------------------------------------------------------------------------------
# Note: Graylog2-server application had a dependency with testcontainers.
# ====  Testcontainers communicate with other containers through docker.sock.
#       Use options (--network="host" & -v /var/run/docker.sock:/var/run/docker.sock) if
#       running the graylog2-server using docker container environment.
# --------------------------------------------------------------------------------------
#!/bin/bash

# Checkout master with specific commit due to release 3.3.13/4.0.7 is unstable.
VERSION=20204a7979569aef116a1bdf30f4b9df6c52bc4d
MAVEN_VERSION=3.6.3

# Install dependencies and tools.
yum update -y
yum install -y git wget java-1.8.0-openjdk-devel
export JAVA_HOME=export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# Install maven package
wget https://www-us.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz --no-check-certificate --quiet
tar xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz

# Set ENV variables
export M2_HOME=`pwd`/apache-maven-${MAVEN_VERSION}
export PATH=`pwd`/apache-maven-${MAVEN_VERSION}/bin:${PATH}

# Clone and build source
git clone https://github.com/Graylog2/graylog2-server.git
cd graylog2-server/
git checkout $VERSION

# Compile and build package
mvn clean package -DskipTests

# Below issues are expected during the execution of graylog2-server test suite.
# 1. Official mongo image for ppc64le is not available from docker.io registry which redirect to use enterprise version.
# 2. Facing "Exception authenticating MongoCredential" problem with enterprise version of 
#    mongo image(ibmcom/ibm-enterprise-mongodb-ppc64le:4.4).
#
# Follow below steps to resolve issues (1)&(2):
# 1. git clone https://github.ibm.com/krishvoor/ibm-mongodb-enterprise.git
# 2. Disable code in file(ibm-mongodb-enterprise/docker/scripts/mongo_init.sh) L14 to L46
# 3. Build mongo image using command "docker build . -t mongo:4.4"
# 4. Push mongo:4.4 image to the registry (example: docker.io/ or your-private.dev/).
#    Note: Skip step#6 & step#7 only if mongo image pushed to docker.io registry.
# 5. Execute command "sed -i 's/3.6/4.4/g' ./graylog2-server/src/test/java/org/graylog/testing/mongodb/MongoDBContainer.java"
#    for modify the mongo version in graylog2-server test code.
# 6. Download ryuk & alpine image from docker.io registry and push it to the same registry where mongo image pushed.
# 7. Create ".testcontainers.properties" file under $HOME directory and copy the below content.
#       hub.image.name.prefix=your-private.dev/
#       ryuk.container.image=docker.io/testcontainers/ryuk:0.3.1
#       tinyimage.container.image=docker.io/ppc64le/alpine

# Command to build graylog2-server with tests
#
# mvn clean package
