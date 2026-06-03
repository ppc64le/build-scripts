#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package         : che-code
# Version         : 7.117.0
# Source repo     : https://github.com/che-incubator/che-code
# Tested on       : rhel_9.7
# Language        : TypeScript
# Ci-Check        : True
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
# podman must be installed and running.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_URL=https://github.com/che-incubator/che-code
PACKAGE_NAME=che-code
VERSION=7.117.0

export CWD=`pwd`

yum update -y
yum install git wget podman -y

########## Container-in-Container Compatibility Patch ##########

# # Install buildah
# yum install -y buildah fuse-overlayfs

# # Clean any existing storage to start fresh in CI
# rm -rf /var/lib/containers/storage/* /run/containers/storage/* 2>/dev/null || true

# # Create necessary directories with proper permissions
# mkdir -p /var/lib/containers/storage
# mkdir -p /run/containers/storage
# mkdir -p /etc/containers
# chmod 755 /var/lib/containers/storage /run/containers/storage

# # Configure storage with proper root and runroot paths
# cat > /etc/containers/storage.conf <<'EOF'
# [storage]
# driver = "vfs"
# runroot = "/run/containers/storage"
# graphroot = "/var/lib/containers/storage"

# [storage.options]
# pull_options = {enable_partial_images = "false", use_hard_links = "false", ostree_repos=""}

# [storage.options.vfs]
# ignore_chown_errors = "true"
# EOF

# # Configure containers runtime to avoid systemd/cgroup issues
# cat > /etc/containers/containers.conf <<'EOF'
# [engine]
# cgroup_manager = "cgroupfs"
# events_logger = "file"

# [containers]
# netns = "host"
# userns = "host"
# ipcns = "host"
# utsns = "host"
# cgroupns = "host"
# EOF

# # Critical environment variables
# export BUILDAH_ISOLATION=chroot
# export STORAGE_DRIVER=vfs
# export BUILDAH_LAYERS=false

# # Prevent user namespace attempts
# unset XDG_RUNTIME_DIR

# # Additional safety flags
# export BUILDAH_FORMAT=docker
# export TMPDIR=/tmp

# # Verify buildah is working
# echo "Testing buildah configuration..."
# buildah --version || { echo "Buildah installation failed"; exit 1; }

# # Test buildah with a simple command to ensure runroot is properly configured
# buildah images > /dev/null 2>&1 || { echo "Buildah runroot configuration failed"; exit 1; }
# echo "Buildah configuration verified successfully"

######################

# Clone repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $VERSION

# Download Dockerfile
wget https://raw.githubusercontent.com/prabhuk25/build-scripts/refs/heads/che-code/e/eclipse-che/che-incubator/che-code/Dockerfiles/linux-musl.Dockerfile

cp build/dockerfiles/linux-libc-ubi8.Dockerfile .
cp build/dockerfiles/linux-libc-ubi9.Dockerfile .
cp build/dockerfiles/assembly.Dockerfile .

# Patch package-lock.json
sed -i '/@vscode\/vsce-sign/,/\}/s/"hasInstallScript": true/"hasInstallScript": false/' code/build/package-lock.json

#Build linux-musl image
echo "linux-musl build started"
podman build -t linux-musl -f linux-musl.Dockerfile
echo "linux-musl build completed"

#Build linux-libc-ubi8
echo "linux-libc-ubi8 build started"
podman build -t linux-libc-ubi8 -f linux-libc-ubi8.Dockerfile
echo "linux-libc-ubi8 build completed"

#Build linux-libc-ubi9
echo "linux-libc-ubi9 build started"
podman build -t linux-libc-ubi9 -f linux-libc-ubi9.Dockerfile
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
podman build -t che-code -f assembly.Dockerfile
echo "che-code build completed"

#If you want to test image, use below command
#docker run --rm -it -p 3100:3100 -e CODE_HOST=0.0.0.0 che-code:latest
