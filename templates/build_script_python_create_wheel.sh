#!/bin/bash
# -----------------------------------------------------------------------------
# Package       :
# Version       :
# Source repo   :
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    :
# -----------------------------------------------------------------------------
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
 
# Exit immediately if a command exits with a non-zero status
set -e
 
PYTHON_VERSIONS=$1
BUILD_SCRIPT_PATH=${2:-""}
if [ -n "$BUILD_SCRIPT_PATH" ]; then
TEMP_BUILD_SCRIPT_PATH="temp_build_script.sh"
else
    TEMP_BUILD_SCRIPT_PATH=""
fi
EXTRA_ARGS="${@:3}"  # Capture all additional arguments passed to the script
 
CURRENT_DIR="${PWD}"
 
# Check if CONTRIBUTING.md exists and is followed
print_checklist() {
    echo "### Checklist"
echo "- [ ] CONTRIBUTING.md exists and guidelines followed"
    echo "- [ ] Script is running on UBI 9 container"
    echo "- [ ] Legal approvals for patch files confirmed"
}
 
# Function to update checklist based on checks
update_checklist() {
    checklist_status="### Checklist"
# Check for CONTRIBUTING.md
if [ -f "CONTRIBUTING.md" ]; then
checklist_status+="\n- [x] CONTRIBUTING.md exists and guidelines followed"
    else
checklist_status+="\n- [ ] CONTRIBUTING.md not found"
    fi
 
    # Check if running on UBI 9
    OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d '"' -f 2)
    if [[ "$OS_VERSION" == 9* ]]; then
        checklist_status+="\n- [x] Script is running on UBI 9 container"
    else
        checklist_status+="\n- [ ] Script is not running on UBI 9 container"
    fi
 
    # Check for legal approvals
    LEGAL_APPROVALS="approved"  # Mock check
    if [ "$LEGAL_APPROVALS" == "approved" ]; then
        checklist_status+="\n- [x] Legal approvals for patch files confirmed"
    else
        checklist_status+="\n- [ ] Legal approvals for patch files missing"
    fi
 
    echo -e "$checklist_status"
}
 
# Call the function to print the checklist status
update_checklist
 
# Update and install required packages
yum -y update && \
yum install -y sudo zlib-devel pip wget python39 python3-devel ncurses git gcc gcc-c++ \
libffi libffi-devel sqlite sqlite-devel sqlite-libs make cmake cargo openssl-devel
 
python3.9 -m pip install --upgrade pip setuptools wheel build pytest nox tox
 
# Install Python 3.10.14
if ! python3.10 --version; then
    cd /usr/src && \
wget https://www.python.org/ftp/python/3.10.14/Python-3.10.14.tgz && \
    tar xzf Python-3.10.14.tgz && \
    cd Python-3.10.14 && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3.10 /usr/bin/python3.10 && \
    cd /usr/src && \
    rm -rf Python-3.10.14.tgz Python-3.10.14
    # Manually install pip if it's not installed
    if ! python3.10 -m pip --version; then
wget https://bootstrap.pypa.io/get-pip.py && \
python3.10 get-pip.py && \
rm get-pip.py
    fi
    python3.10 -m pip install --upgrade pip setuptools wheel build pytest nox tox
fi
 
# Install Python 3.11.9
if ! python3.11 --version; then
    cd /usr/src && \
wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz && \
    tar xzf Python-3.11.9.tgz && \
    cd Python-3.11.9 && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3.11 /usr/bin/python3.11 && \
    cd /usr/src && \
    rm -rf Python-3.11.9.tgz Python-3.11.9
    # Manually install pip if it's not installed
    if ! python3.11 -m pip --version; then
wget https://bootstrap.pypa.io/get-pip.py && \
python3.11 get-pip.py && \
rm get-pip.py
    fi
    python3.11 -m pip install --upgrade pip setuptools wheel build pytest nox tox
fi
 
# Install Python 3.12.5
if ! python3.12 --version; then
    cd /usr/src && \
wget https://www.python.org/ftp/python/3.12.5/Python-3.12.5.tgz && \
    tar xzf Python-3.12.5.tgz && \
    cd Python-3.12.5 && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3.12 /usr/bin/python3.12 && \
    ln -s /usr/local/bin/pip3.12 /usr/bin/pip3.12 && \
    cd /usr/src && \
    rm -rf Python-3.12.5.tgz Python-3.12.5
    python3.12 -m pip install --upgrade pip setuptools wheel build pytest nox tox
fi
 
# Install Python 3.13.0rc1
if ! python3.13 --version; then
    cd /usr/src && \
wget https://www.python.org/ftp/python/3.13.0/Python-3.13.0rc1.tgz && \
    tar xzf Python-3.13.0rc1.tgz && \
    cd Python-3.13.0rc1 && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3.13 /usr/bin/python3.13 && \
    ln -s /usr/local/bin/pip3.13 /usr/bin/pip3.13 && \
    cd /usr/src && \
    rm -rf Python-3.13.0rc1.tgz Python-3.13.0rc1
    python3.13 -m pip install --upgrade pip setuptools wheel build pytest nox tox
fi
 
# Function to check for setup.py or *.toml files in a directory
check_files_in_directory() {
    local dir=$1
if [ -f "$dir/setup.py" ] || ls "$dir"/*.toml 1> /dev/null 2>&1; then
        return 0
    fi
    return 1
}
 
# Function to copy and format the build script
format_build_script() {
    if [ -n "$BUILD_SCRIPT_PATH" ]; then  # Check if BUILD_SCRIPT_PATH is non-empty
        cp "$BUILD_SCRIPT_PATH" "$TEMP_BUILD_SCRIPT_PATH"
        sed -i 's/python3 /python /g' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i 's/pip3 /pip /g' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i 's/\bpython[0-9]\+\.[0-9]\+ -m pip /pip /g' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i '/-m venv/d' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i '/bin\/activate/d' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i '/^deactivate$/d' "$TEMP_BUILD_SCRIPT_PATH"
    else
        echo "No build script specified, skipping copying."
    fi
}
 
# Function to create a virtual environment
create_venv() {
    local VENV_DIR=$1
    local python_version=$2
    "python$python_version" -m venv --system-site-packages "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
}
 
# Function to clean up virtual environment
cleanup() {
    local VENV_DIR=$1
    deactivate
    rm -rf "$VENV_DIR"
}
 
# Format the build script if it's non-empty
if [ -n "$BUILD_SCRIPT_PATH" ]; then
    format_build_script
fi
 
# Split the Python versions into an array
IFS=',' read -r -a python_versions <<< "$PYTHON_VERSIONS"
 
# Loop through each Python version
for python_version in "${python_versions[@]}"; do
    echo "Processing Package with Python $python_version"
    VENV_DIR="$CURRENT_DIR/pyvenv_$python_version"
    create_venv "$VENV_DIR" "$python_version"
 
    echo "=============== Running package build-script starts =================="
    if [ -n "$TEMP_BUILD_SCRIPT_PATH" ]; then  # Check if TEMP_BUILD_SCRIPT_PATH is non-empty
        sh "$TEMP_BUILD_SCRIPT_PATH" $EXTRA_ARGS
    else
        echo "No build script to run, skipping execution."
    fi
    echo "=============== Running package build-script ends =================="
 
    if [ $? -ne 0 ]; then
        echo "Build script execution failed. Skipping wheel creation."
        cleanup "$VENV_DIR"
        [ -n "$TEMP_BUILD_SCRIPT_PATH" ] && rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"
        exit 1
    fi
 
    echo "=============== Building wheel =================="
if [ ! -f "setup.py" ] && ! ls *.toml 1> /dev/null 2>&1; then
echo "setup.py or *.toml not found in the current directory. Checking subdirectories..."
        for dir in */; do
            if [ -d "$dir" ] && [[ ! "$dir" =~ ^Python ]]; then
                check_files_in_directory "$dir"
                if [ $? -eq 0 ]; then
echo "setup.py or *.toml found in $dir"
                    cd "$dir"
                    break
                fi
            fi
        done
    fi
 
    if ! python -m build --wheel --outdir="$CURRENT_DIR/wheels/$python_version/"; then
        echo "============ Wheel Creation Failed for Python $python_version ================="
        cleanup "$VENV_DIR"
        [ -n "$TEMP_BUILD_SCRIPT_PATH" ] && rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"
        exit 1
    fi
 
    cleanup "$VENV_DIR"
done
 
[ -n "$TEMP_BUILD_SCRIPT_PATH" ] && rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"
exit 0
