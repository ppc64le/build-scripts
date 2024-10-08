#!/bin/bash
# How to run?
# sh templates/build_script_python_create_wheel.sh "3.9" o/odoo/odoo_ubi_9.3.sh
# sh templates/build_script_python_create_wheel.sh "3.9" b/bandersnatch/bandersnatch_ubi_9_3.sh
# sh templates/build_script_python_create_wheel.sh "3.9" m/metricbeat/metricbeat_ubi_9_3.sh
# sh templates/build_script_python_create_wheel.sh "3.9" p/pytest-aiohttp/pytest-aiohttp_ubi_9.3.sh

PYTHON_VERSIONS=$1
BUILD_SCRIPT_PATH=$2
TEMP_BUILD_SCRIPT_PATH="temp_build_script.sh"
EXTRA_ARGS="${@:3}" # Capture all additional arguments passed to the script
CURRENT_DIR="${PWD}"

# Update and install required packages in a single command
yum -y update && \
yum install -y sudo \
wget \
python39 python3-devel \
ncurses git gcc gcc-c++ \
libffi libffi-devel \
sqlite sqlite-devel sqlite-libs \
make cmake cargo openssl-devel

python3.9 -m pip install --upgrade pip setuptools wheel build pytest nox tox

# Install python 3.10.14
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

# Install python 3.11.9
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

# Install python 3.12.5
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

# Install python 3.13.0
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
    # Copy $BUILD_SCRIPT_PATH file and save it as $TEMP_BUILD_SCRIPT_PATH
    cp "$BUILD_SCRIPT_PATH" "$TEMP_BUILD_SCRIPT_PATH"

    # Replace "python3 " with "python " and "pip3 " with "pip " in the copied file
    sed -i 's/python3 /python /g' "$TEMP_BUILD_SCRIPT_PATH"
    sed -i 's/pip3 /pip /g' "$TEMP_BUILD_SCRIPT_PATH"

    # Replace lines like "pythonX.Y -m pip" with "pip "
    sed -i 's/\bpython[0-9]\+\.[0-9]\+ -m pip /pip /g' "$TEMP_BUILD_SCRIPT_PATH"

    # Remove any line that contains the Python installation download command
    # sed -i '/wget https:\/\/www\.python\.org\/ftp\/python/d' "$TEMP_BUILD_SCRIPT_PATH"

    # Remove lines containing the "-m venv" command
    sed -i '/-m venv/d' "$TEMP_BUILD_SCRIPT_PATH"

    # Remove lines starting with "source " and ending with "/bin/activate"
    sed -i '/bin\/activate/d' "$TEMP_BUILD_SCRIPT_PATH"

    # Remove lines containing only the "deactivate" command
    sed -i '/^deactivate$/d' "$TEMP_BUILD_SCRIPT_PATH"
}

create_venv() {
    local VENV_DIR=$1
    local python_version=$2
    # Create a virtual environment
    "python$python_version" -m venv --system-site-packages "$VENV_DIR"
    # Activate the virtual environment
    source "$VENV_DIR/bin/activate"
}

cleanup() {
    local VENV_DIR=$1
    # Deactivate and remove the virtual environment
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
    # Run the temporary build script with dynamic extra arguments
    sh "$TEMP_BUILD_SCRIPT_PATH" $EXTRA_ARGS
    echo "=============== Running package build-script ends =================="

    # Check if the build script executed successfully
    if [ $? -ne 0 ]; then
        echo "Build script execution failed. Skipping wheel creation."
        cleanup "$VENV_DIR"
        rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"
        exit 1
    fi

    # To build wheel and store it in (wheels) folder
    echo "=============== Building wheel =================="

# Check if setup.py or *.toml exists in the current directory
if [ ! -f "setup.py" ] && ! ls *.toml 1> /dev/null 2>&1; then
echo "setup.py or *.toml not found in the current directory. Checking subdirectories..."

        # Find and loop through subdirectories
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

    # Build the wheel and output to the designated directory
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
