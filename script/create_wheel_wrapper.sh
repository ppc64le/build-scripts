#!/bin/bash -e

PYTHON_VERSION=$1
BUILD_SCRIPT_PATH=${2:-""}
EXTRA_ARGS="${@:3}" # Capture all additional arguments passed to the script
CURRENT_DIR="${PWD}"

# Temporary build script path
if [ -n "$BUILD_SCRIPT_PATH" ]; then
    TEMP_BUILD_SCRIPT_PATH="temp_build_script.sh"
else
    TEMP_BUILD_SCRIPT_PATH=""
fi

# Function to install a specific Python version
install_python_version() {
    local version=$1
    echo "Installing Python version: $version"
    case $version in
    "3.9" | "3.11" | "3.12")
        yum install -y python${version} python${version}-devel python${version}-pip
        ;;
    "3.10")
        if ! python3.10 --version &>/dev/null; then
            echo "Installing dependencies required for python installation..."
            yum install -y sudo zlib-devel wget ncurses git gcc gcc-c++ make cmake \
                libffi libffi-devel sqlite sqlite-devel sqlite-libs openssl-devel
            wget https://www.python.org/ftp/python/3.10.15/Python-3.10.15.tgz
            tar xf Python-3.10.15.tgz
            cd Python-3.10.15
            ./configure --prefix=/usr/local --enable-optimizations
            echo "Still building..."
            make -j2
            echo "Still building..."
            make altinstall
            echo "Completed..."
            cd .. && rm -rf Python-3.10.15.tgz
        fi
        ;;
    "3.13")
        if ! python3.13 --version &>/dev/null; then
            echo "Installing dependencies required for python installation..."
            yum install -y sudo zlib-devel wget ncurses git gcc gcc-c++ make cmake \
                libffi libffi-devel sqlite sqlite-devel sqlite-libs openssl-devel
            wget https://www.python.org/ftp/python/3.13.0/Python-3.13.0.tgz
            tar xzf Python-3.13.0.tgz
            cd Python-3.13.0
            ./configure --prefix=/usr/local --enable-optimizations
            echo "Still building..."
            make -j2
            echo "Still building..."
            make altinstall
            echo "Completed..."
            cd .. && rm -rf Python-3.13.0.tgz
        fi
        ;;
    *)
        echo "Unsupported Python version: $version"
        exit 1
        ;;
    esac
}

# Install the specified Python version
install_python_version "$PYTHON_VERSION"

# Function to check for setup.py or *.toml files in a directory
check_files_in_directory() {
    local dir=$1

    if [ -f "$dir/setup.py" ] || ls "$dir"/*.toml 1>/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Function to copy and format the build script
format_build_script() {
    if [ -n "$BUILD_SCRIPT_PATH" ]; then
        cp "$BUILD_SCRIPT_PATH" "$TEMP_BUILD_SCRIPT_PATH"

        # Modify the build script for compatibility
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

# Function to clean up the virtual environment
cleanup() {
    local VENV_DIR=$1

    deactivate
    rm -rf "$VENV_DIR"
}

# Format the build script if it's non-empty
if [ -n "$BUILD_SCRIPT_PATH" ]; then
    format_build_script
fi

echo "Processing Package with Python $PYTHON_VERSION"

# Create and activate virtual environment
VENV_DIR="$CURRENT_DIR/pyvenv_$PYTHON_VERSION"
create_venv "$VENV_DIR" "$PYTHON_VERSION"

echo "=============== Running package build-script starts =================="

if [ -n "$TEMP_BUILD_SCRIPT_PATH" ]; then
    python$PYTHON_VERSION -m pip install --upgrade pip setuptools wheel build pytest nox tox
      
    package_url=$(grep -oP '(?<=^PACKAGE_URL=).*' "$TEMP_BUILD_SCRIPT_PATH" | tr -d '"')
    package_name=$(basename "$package_url" .git)
    

    sh "$TEMP_BUILD_SCRIPT_PATH" $EXTRA_ARGS
else
    echo "No build script to run, skipping execution."
fi

echo "=============== Running package build-script ends =================="

# Check if the build script execution was successful
if [ $? -ne 0 ]; then
    echo "Build script execution failed. Skipping wheel creation."
    cleanup "$VENV_DIR"
    [ -n "$TEMP_BUILD_SCRIPT_PATH" ] && rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"
    exit 1
fi

# Navigate to the package directory
echo "Navigating to the package directory"
cd $package_name

echo "=============== Building wheel =================="

# Check for setup.py or *.toml files in the current directory or subdirectories
if [ ! -f "setup.py" ] && ! ls *.toml 1>/dev/null 2>&1; then
    echo "setup.py or *.toml not found in the current directory. Checking subdirectories..."
    dir=$(find . -type f -name "setup.py" -o -name "*.toml" -print -quit | xargs -I {} dirname "{}")

    if [ -n "$dir" ]; then
        echo "setup.py or *.toml found in $dir"
        cd "$dir"
    else
        echo "No setup.py or *.toml found in any subdirectory."
    fi
else
    echo "========= setup.py or *.toml found in the package directory ========="
fi

# Attempt to build the wheel with isolation
if ! python -m build --wheel --outdir="$CURRENT_DIR/"; then
    echo "============ Wheel Creation Failed for Python $PYTHON_VERSION ================="
    echo "Attempting to build without isolation..."

    # Attempt to build the wheel without isolation
    if ! python -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"; then
        echo "============ Wheel Creation Failed for Python $PYTHON_VERSION (without isolation) ================="
        cleanup "$VENV_DIR"
        [ -n "$TEMP_BUILD_SCRIPT_PATH" ] && rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"
        exit 1
    fi
fi

# Clean up virtual environment
cleanup "$VENV_DIR"

# Remove temporary build script
[ -n "$TEMP_BUILD_SCRIPT_PATH" ] && rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"

exit 0
