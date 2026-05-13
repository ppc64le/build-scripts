#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package         : che-code
# Version         : 7.117.0
# Source repo     : https://github.com/che-incubator/che-code
# Tested on       : rhel_9.7
# Script License  : Eclipse Public License - v 2.0
# Maintainer      : Prabhu K <Prabhu.K@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Prerequisites:
#
# docker must be installed and running.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_URL=https://github.com/che-incubator/che-code
PACKAGE_NAME=che-code
VERSION=7.117.0

export CWD=`pwd`

yum update -y
yum install git -y

########## Container-in-Container Compatibility Patch (Only required for CI/containerized environments) #########

# Configure Podman/docker to use vfs storage driver for container-in-container compatibility
mkdir -p /etc/containers && cat > /etc/containers/storage.conf <<'EOF'
[storage]
driver = "vfs"
EOF

# Install container build dependencies and force safe chroot isolation for Podman in restricted/container environments
yum install -y buildah podman fuse-overlayfs
export BUILDAH_ISOLATION=chroot

######################

yum install docker -y

#Clone repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $VERSION

#Move dockerfiles to main folder
cp $CWD/Dockerfiles/linux-musl.Dockerfile .
cp build/dockerfiles/linux-libc-ubi8.Dockerfile .
cp build/dockerfiles/linux-libc-ubi9.Dockerfile .
cp build/dockerfiles/assembly.Dockerfile .

#Patch package-lock.json to skip @vscode/vsce-sign, since it has no binary for ppc64le and its exit with code 1 on postinstall.
sed -i '/@vscode\/vsce-sign/,/\}/s/"hasInstallScript": true/"hasInstallScript": false/' \
       code/build/package-lock.json; \

#Build linux-musl image
echo "linux-musl build started"
docker build -t linux-musl -f linux-musl.Dockerfile
echo "linux-musl build completed"

#Build linux-libc-ubi8
echo "linux-libc-ubi8 build started"
docker build -t linux-libc-ubi8 -f linux-libc-ubi8.Dockerfile
echo "linux-libc-ubi8 build completed"

#Build linux-libc-ubi9
echo "linux-libc-ubi9 build started"
docker build -t linux-libc-ubi9 -f linux-libc-ubi9.Dockerfile
echo "linux-libc-ubi9 build completed"

#Patch the images names to use locally build images in assesbly.Dockerfile
sed -i \
-e 's|FROM linux-libc-ubi8|FROM localhost/linux-libc-ubi8|' \
-e 's|FROM linux-libc-ubi9|FROM localhost/linux-libc-ubi9|' \
-e 's|FROM linux-musl|FROM localhost/linux-musl|' \
assembly.Dockerfile

#Build che-code
echo "che-
code build started"
docker build -t che-code -f assembly.Dockerfile
echo "che-code build completed"

#If you want to test image, use below command
#docker run --rm -it -p 3100:3100 -e CODE_HOST=0.0.0.0 che-code:latest

