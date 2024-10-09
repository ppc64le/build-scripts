#!/bin/bash
 
# Exit immediately if a command exits with a non-zero status
set -e
 
PYTHON_VERSIONS=$1
BUILD_SCRIPT_PATH=$2
TEMP_BUILD_SCRIPT_PATH="temp_build_script.sh"
EXTRA_ARGS="${@:3}"  # Capture all additional arguments passed to the script
CURRENT_DIR="${PWD}"
 
# Check if CONTRIBUTING.md exists and is followed
if [ ! -f "CONTRIBUTING.md" ]; then
echo "Error: CONTRIBUTING.md not found. Please ensure it exists and follow all points mentioned in it."
    exit 1
fi
 
# Check if script is being run on UBI 9 container
OS_VERSION=$(cat /etc/os-release | grep "^VERSION_ID=" | cut -d '"' -f 2)
if [ "$OS_VERSION" != "9" ]; then
    echo "Error: Script is not running on UBI 9 container. Please validate on UBI 9."
    exit 1
fi
 
# Check for legal approvals for patch files
LEGAL_APPROVALS="approved"
if [ "$LEGAL_APPROVALS" != "approved" ]; then
    echo "Error: Legal approvals for patch files are missing."
    exit 1
fi
 
# Update and install required packages in a single command
yum -y update && \
yum install -y sudo wget python39 python3-devel ncurses git gcc gcc-c++ \
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
    ln -s /usr/local/bin/pip3.10 /usr/bin/pip3.10 && \
    cd /usr/src && \
    rm -rf Python-3.10.14.tgz Python-3.10.14
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
    ln -s /usr/local/bin/pip3.11 /usr/bin/pip3.11 && \
    cd /usr/src && \
    rm -rf Python-3.11.9.tgz Python-3.11.9
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
 
# Install Python 3.13.0
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
    cp "$BUILD_SCRIPT_PATH" "$TEMP_BUILD_SCRIPT_PATH"
    sed -i 's/python3 /python /g' "$TEMP_BUILD_SCRIPT_PATH"
    sed -i 's/pip3 /pip /g' "$TEMP_BUILD_SCRIPT_PATH"
    sed -i 's/\bpython[0-9]\+\.[0-9]\+ -m pip /pip /g' "$TEMP_BUILD_SCRIPT_PATH"
    sed -i '/-m venv/d' "$TEMP_BUILD_SCRIPT_PATH"
    sed -i '/bin\/activate/d' "$TEMP_BUILD_SCRIPT_PATH"
    sed -i '/^deactivate$/d' "$TEMP_BUILD_SCRIPT_PATH"
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
 
# Format the build script
format_build_script
 
# Split the Python versions into an array
IFS=',' read -r -a python_versions <<< "$PYTHON_VERSIONS"
 
# Loop through each Python version
for python_version in "${python_versions[@]}"; do
    echo "Processing Package with Python $python_version"
    VENV_DIR="$CURRENT_DIR/pyvenv_$python_version"
    create_venv "$VENV_DIR" "$python_version"
 
    echo "=============== Running package build-script starts =================="
    sh "$TEMP_BUILD_SCRIPT_PATH" $EXTRA_ARGS
    echo "=============== Running package build-script ends =================="
 
    if [ $? -ne 0 ]; then
        echo "Build script execution failed. Skipping wheel creation."
        cleanup "$VENV_DIR"
        rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"
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
        rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"
        exit 1
    fi
 
    cleanup "$VENV_DIR"
done
 
rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"
exit 0
