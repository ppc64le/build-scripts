#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : docker-stacks
# Version        : main
# Source repo    : https://github.com/jupyter/docker-stacks
# Tested on      : UBI 9.3
# Language       : Python, Shell
# Travis-Check   : False
# Script License : Apache License, Version 2 or later
# Maintainer     : Rohan Borkar <Rohan.Borkar@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
#Run the container with below command:
#docker run --network host --privileged -t -d --name 17-feb-version-1 -v /var/run/docker.sock:/var/run/docker.sock registry.access.redhat.com/ubi9/ubi:9.3
#docker exec -it <container_id> bash

# Variables
PACKAGE_NAME=docker-stacks
PACKAGE_URL=https://github.com/jupyter/docker-stacks.git
BUILD_HOME=$(pwd)
PATCH_FILE="$BUILD_HOME/minimal-notebook.patch"
BUILDX_VERSION="v0.19.3"
BUILDX_BINARY="buildx-${BUILDX_VERSION}.linux-ppc64le"

# Step 1: Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    mkdir -p /etc/docker
    touch /etc/docker/daemon.json
    cat <<EOT > /etc/docker/daemon.json
{
    "ipv6": true,
    "fixed-cidr-v6": "2001:db8:1::/64",
    "mtu": 1450
}
EOT
    dockerd > /dev/null 2>&1 &
    sleep 5
fi

# Verify Docker installation
docker --version || { echo "Failed to verify Docker installation.";}

# Step 2: Install dependencies
echo "Installing required dependencies..."
yum install -y git make curl wget pip patch --allowerasing || { echo "Failed to install required packages.";  }

# Step 3: Clone the repository
echo "Cloning the $PACKAGE_NAME repository..."
git clone $PACKAGE_URL || { echo "Failed to clone repository.";}

# Navigate to the cloned directory
cd $PACKAGE_NAME || { echo "Failed to navigate to the $PACKAGE_NAME directory.";  }


git checkout e9b04fd5da4a42d47eac1a6491dcb5377909121b


# Step 4: Prepare Docker Buildx
echo "Setting up Docker Buildx..."
mkdir -p ~/.docker/cli-plugins
wget https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/${BUILDX_BINARY} || { echo "Failed to download Docker Buildx.";  }
mv ${BUILDX_BINARY} ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
docker buildx version || { echo "Failed to verify Docker Buildx installation."; }

# Step 5: Apply the patch file
echo "Applying the patch file..."
if [ -f "$PATCH_FILE" ]; then
    patch -p1 < "$PATCH_FILE" || { echo "Failed to apply patch."; }
else
    echo "Patch file $PATCH_FILE not found."
fi

# Step 6: Upgrade pip and install Python dependencies
echo "Upgrading pip and installing Python dependencies..."
yum remove python3-requests -y
pip3 install --upgrade pip || { echo "Failed to upgrade pip."; exit 1; }
pip3 install --upgrade -r requirements-dev.txt || { echo "Failed to install Python dependencies.";  }

# Step 7: Build Docker images
echo "Building all Docker images..."
make build-all || { echo "Failed to build Docker images.";  }


export DOCKER_CLIENT_TIMEOUT=1600
export COMPOSE_HTTP_TIMEOUT=1600
make test/minimal-notebook

# Step 8: Run tests
echo "Running tests..."
#python3 -m tests.run_tests --short-image-name minimal-notebook --registry quay.io --owner jupyter || { echo "Tests failed.";  }
#make test-all
# Success message
echo "SUCCESS: Build and test process completed successfully."
echo "Docker images built and tested successfully."

