#!/bin/bash -e
# ----------------------------------------------------------------------------- 
#
# Package          : dask
# Versions         : 2.20.0 (default) and 2023.3.2
# Source repo      : https://github.com/dask/dask.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rakshith B R <rakshith.r5@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=dask
PACKAGE_VERSION=${1:-2.20.0}  # Default version set to 2.20.0
PACKAGE_URL=https://github.com/dask/dask.git
VENV_DIR="dask_env"

# Function to install dependencies
install_dependencies() {
  # Install necessary system dependencies
  yum install -y git gcc gcc-c++ make wget python3-devel python3-pip libyaml-devel
}

# Function to upgrade pip and install necessary Python packages
upgrade_pip_and_install_python_deps() {
  pip install --upgrade pip setuptools wheel
}

# Function to create and activate a virtual environment
create_virtual_env() {
  python3 -m venv $VENV_DIR
  source $VENV_DIR/bin/activate
}

# Function to clone repository and checkout specified version
clone_and_checkout_repo() {
  # Check if the 'dask' directory already exists, and remove it if necessary
  if [ -d "$PACKAGE_NAME" ]; then
    echo "Directory '$PACKAGE_NAME' already exists, removing it..."
    rm -rf $PACKAGE_NAME
  fi

  # Clone the repository
  git clone $PACKAGE_URL
  cd $PACKAGE_NAME  
  git checkout $PACKAGE_VERSION  
}

# Function to install additional dependencies
install_additional_dependencies() {
  # Install required additional dependencies
  pip install toolz packaging importlib_metadata cloudpickle
}

# Function to install Dask from the cloned repository
install_dask() {
  # Install Dask in editable mode
  pip install -e .
}

# Function to build and install the package
build_and_install_package() {
  if ! python3 setup.py install; then
    echo "------------------$PACKAGE_NAME: Install failed-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Failed"
    exit 1
  fi
}

# Main script execution
echo "Starting installation of $PACKAGE_NAME version $PACKAGE_VERSION..."

install_dependencies
create_virtual_env  # Create and activate virtual environment
upgrade_pip_and_install_python_deps
clone_and_checkout_repo
install_additional_dependencies  # Install toolz, packaging, importlib_metadata, cloudpickle
install_dask
build_and_install_package

echo "$PACKAGE_NAME version $PACKAGE_VERSION installed successfully!"
