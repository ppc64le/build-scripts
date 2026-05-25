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
# docker must be installed and running.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_URL=https://github.com/che-incubator/che-code
PACKAGE_NAME=che-code
VERSION=7.117.0

export CWD=`pwd`

yum update -y
yum install git wget -y

########## Container-in-Container Compatibility Patch ##########

# Install buildah
yum install -y buildah fuse-overlayfs

# Configure storage
mkdir -p /etc/containers
cat > /etc/containers/storage.conf <<'EOF'
[storage]
driver = "vfs"
EOF

# Configure containers runtime to avoid systemd/cgroup issues
cat > /etc/containers/containers.conf <<'EOF'
[engine]
cgroup_manager = "cgroupfs"
events_logger = "file"

[containers]
netns = "host"
userns = "host"
ipcns = "host"
utsns = "host"
cgroupns = "host"
EOF

# Critical environment variables
export BUILDAH_ISOLATION=chroot
export STORAGE_DRIVER=vfs
export BUILDAH_LAYERS=false
# Prevent user namespace attempts
unset XDG_RUNTIME_DIR
# Additional safety flags
export BUILDAH_FORMAT=docker
export TMPDIR=/tmp

# Verify buildah is working
echo "Testing buildah configuration..."
buildah --version || { echo "Buildah installation failed"; exit 1; }

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

# Build function with error handling
build_image() {
    local name=$1
    local dockerfile=$2

    echo "$name build started"

    # Try with all safety flags
    if buildah bud \
        --isolation=chroot \
        --storage-driver=vfs \
        --format=docker \
        --layers=false \
        --no-cache \
        --pull=never \
        -t "$name" \
        -f "$dockerfile" \
        . ; then
        echo "$name build completed successfully"
        return 0
    else
        echo "ERROR: $name build failed"
        return 1
    fi
}

# Build images
build_image "linux-musl" "linux-musl.Dockerfile"
build_image "linux-libc-ubi8" "linux-libc-ubi8.Dockerfile"
build_image "linux-libc-ubi9" "linux-libc-ubi9.Dockerfile"

echo "Available local images:"
buildah images

# Verify all required images exist before building assembly
echo "Verifying required images..."
for img in linux-musl linux-libc-ubi8 linux-libc-ubi9; do
    if buildah images | grep -q "localhost/$img"; then
        echo "✓ Found localhost/$img"
    else
        echo "✗ ERROR: localhost/$img not found!"
        exit 1
    fi
done

# Patch assembly.Dockerfile to use localhost prefix
echo "Patching assembly.Dockerfile to use local images..."
sed -i \
-e 's|FROM linux-libc-ubi8|FROM localhost/linux-libc-ubi8|' \
-e 's|FROM linux-libc-ubi9|FROM localhost/linux-libc-ubi9|' \
-e 's|FROM linux-musl|FROM localhost/linux-musl|' \
assembly.Dockerfile

# Verify the patch worked
echo "Verifying assembly.Dockerfile patches..."
grep "FROM localhost/" assembly.Dockerfile || { echo "ERROR: Patch failed"; exit 1; }

# Build final image
build_image "che-code" "assembly.Dockerfile"

#If you want to test image, use below command
#docker run --rm -it -p 3100:3100 -e CODE_HOST=0.0.0.0 che-code:latest
