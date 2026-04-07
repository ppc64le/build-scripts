#!/bin/bash -e

# variables
PYTHON_VERSION=$1
BUILD_SCRIPT_PATH=${2:-""}
EXTRA_ARGS=${3:-""}
POST_PROCESS_SCRIPT_PATH=${4:-"post_process_wheel.py"}
CURRENT_DIR=$(pwd)

# install gcc
yum install -y gcc-toolset-13 
source /opt/rh/gcc-toolset-13/enable
gcc --version

# temporary build script path
if [ -n "$BUILD_SCRIPT_PATH" ]; then
    TEMP_BUILD_SCRIPT_PATH="temp_build_script.sh"
else
    TEMP_BUILD_SCRIPT_PATH=""
fi

# function to install a specific Python version
install_python_version() {
    local version=$1
    echo
    echo "==================== Installing Python version: $version ===================="
    echo
    case $version in
	"3.9")
        yum install -y python3 python3-devel python3-pip
        ;;
    "3.11" | "3.12")
        yum install -y python${version} python${version}-devel python${version}-pip
        ;;
    "3.10")
        if ! python3.10 --version &>/dev/null; then
            yum install -y sudo zlib-devel wget ncurses git make cmake openssl-devel xz xz-devel
            yum install -y libffi libffi-devel sqlite sqlite-devel sqlite-libs bzip2-devel
            wget https://www.python.org/ftp/python/3.10.20/Python-3.10.20.tgz
            tar xf Python-3.10.20.tgz
            cd Python-3.10.20
            ./configure --prefix=/usr/local --enable-optimizations
            make -j2
            make altinstall
            echo "Completed..."
            cd .. && rm -rf Python-3.10.20.tgz
        fi
        ;;
    "3.13")
        if ! python3.13 --version &>/dev/null; then
            yum install -y sudo zlib-devel wget ncurses git make cmake openssl-devel xz xz-devel
            yum install -y libffi libffi-devel sqlite sqlite-devel sqlite-libs bzip2-devel
            wget https://www.python.org/ftp/python/3.13.10/Python-3.13.10.tgz
            tar xzf Python-3.13.10.tgz
            cd Python-3.13.10
            ./configure --prefix=/usr/local --enable-optimizations
            make -j2
            make altinstall
            cd .. && rm -rf Python-3.13.10.tgz
        fi
        ;;
    "3.14")
        if ! python3.14 --version &>/dev/null; then
            yum install -y sudo zlib-devel wget ncurses git make cmake openssl-devel xz xz-devel
            yum install -y libffi libffi-devel sqlite sqlite-devel sqlite-libs bzip2-devel
            wget https://www.python.org/ftp/python/3.14.3/Python-3.14.3.tgz
            tar xzf Python-3.14.3.tgz
            cd Python-3.14.3
            ./configure --prefix=/usr/local --enable-optimizations
            make -j2
            make altinstall
            cd .. && rm -rf Python-3.14.3.tgz
        fi
        ;;
    *)
        echo "Unsupported Python version: $version"
        exit 1
        ;;
    esac
}

# install the specified Python version
install_python_version "$PYTHON_VERSION"

# function to copy and format the build script
format_build_script() {
    if [ -n "$BUILD_SCRIPT_PATH" ]; then
        cp "$BUILD_SCRIPT_PATH" "$TEMP_BUILD_SCRIPT_PATH"

        # modify the build script for compatibility
        sed -i 's/\bpython[0-9]\+\.[0-9]\+ -m pip /pip /g' "$TEMP_BUILD_SCRIPT_PATH"
        #sed -i 's/python[0-9]\+\.[0-9]\+/python/g' "$TEMP_BUILD_SCRIPT_PATH"
        #sed -i 's/python3 /python /g' "$TEMP_BUILD_SCRIPT_PATH"
		#Below change introduces a temporary workaround for building Python from source and will be reverted to above to sed commands after a proper solution is in place.
		sed -i '/^\s*yum remove\|^\s*dnf remove/! s/python[0-9]\+\.[0-9]\+/python/g' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i '/^\s*yum remove\|^\s*dnf remove/! s/python3 /python /g' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i 's/pip3 /pip /g' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i '/-m venv/d' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i '/bin\/activate/d' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i '/^\s*deactivate\s*$/d' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i '/yum install/{s/\(python\|python-devel\|python-pip\)\([[:space:]]\|$\)//g; s/[[:space:]]\+/ /g}' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i '/dnf install/{s/\(python\|python-devel\|python-pip\)\([[:space:]]\|$\)//g; s/[[:space:]]\+/ /g}' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i 's/\bpython3 -m pytest/pytest/g' "$TEMP_BUILD_SCRIPT_PATH"
        sed -i "s/tox -e py[0-9]\{2,3\}\([[:space:]]*.*\)\?/tox -e py${PYTHON_VERSION//./}\1/g" "$TEMP_BUILD_SCRIPT_PATH"
        sed -i 's/^[[:space:]]*exit[[:space:]]\+0[[:space:]]*$//' "$TEMP_BUILD_SCRIPT_PATH"
    else
        echo "No build script specified, skipping copying."
    fi
}

# function to create a virtual environment
create_venv() {
    local VENV_DIR=$1
    local python_version=$2

    "python$python_version" -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
}

# function to clean up the virtual environment
cleanup() {
    local VENV_DIR=$1

    deactivate
    rm -rf "$VENV_DIR"
}

# function to create SHA256 for wheel
generate_sha() {
    local build_script=$1
    local python_version=$2
    local cur_dir=$3
    local wheel=$4

    # Mark repo as safe (to avoid dubious ownership issue)
    git config --global --add safe.directory $cur_dir

    BUILD_SCRIPT_DATE=$(git log -1 --format=%ci -- "${build_script}")
    PACKAGE_LANGUAGE=${PACKAGE_LANGUAGE:-python}

    # Check required variables
    : "${PACKAGE_NAME:?PACKAGE_NAME is required}"
    : "${PACKAGE_VERSION:?PACKAGE_VERSION is required}"
    : "${BUILD_SCRIPT_DATE:?BUILD_SCRIPT_DATE is required}"

    if [[ "$wheel" == *any.whl || "$wheel" == *abi3* || "$wheel" == *none* ]]; then
        string_to_hash="${PACKAGE_NAME}_${PACKAGE_VERSION}_${PACKAGE_LANGUAGE}_${BUILD_SCRIPT_DATE}"
    else
        : "${python_version:?python_version is required}"
        string_to_hash="${PACKAGE_NAME}_${PACKAGE_VERSION}_${PACKAGE_LANGUAGE}_${python_version}_${BUILD_SCRIPT_DATE}"
    fi

    SHA_VALUE=$(echo -n "$string_to_hash" | sha256sum | awk '{print $1}')

    echo "$SHA_VALUE" > "$cur_dir/sha256.sha"

    echo
    echo "===> SHA256 successfully generated for $string_to_hash "
    echo "===> SHA256: $SHA_VALUE "
    echo
}

# format the build script if it's non-empty
if [ -n "$BUILD_SCRIPT_PATH" ]; then
    format_build_script
fi

# create and activate virtual environment
VENV_DIR="$CURRENT_DIR/pyvenv_$PYTHON_VERSION"
create_venv "$VENV_DIR" "$PYTHON_VERSION"

echo
echo "==================== Running package build-script starts ===================="
echo

if [ -n "$TEMP_BUILD_SCRIPT_PATH" ]; then
    python$PYTHON_VERSION -m pip install --upgrade pip wheel build pytest nox tox requests setuptools ibm-cos-sdk auditwheel "patchelf>=0.14"

    package_dir=$(grep -oP '(?<=^PACKAGE_DIR=).*' "$TEMP_BUILD_SCRIPT_PATH" | tr -d '"')
    package_url=$(grep -oP '(?<=^PACKAGE_URL=).*' "$TEMP_BUILD_SCRIPT_PATH" | tr -d '"')
    package_name=$(basename "$package_url" .git)

    source "$TEMP_BUILD_SCRIPT_PATH" "$EXTRA_ARGS"
fi

# checking if wheel is generated through script itself
cd $CURRENT_DIR
if ls *.whl 1>/dev/null 2>&1; then
    echo
    echo "===> Wheel file already exists in the current directory: $(ls *.whl)"
    echo
else
    
    # to handle where setup.py or pyproject.toml file is present
    if [ -d "$package_dir" ]; then
        echo
        echo "===> Navigating to the package directory: $package_dir"
        echo
        cd "$package_dir"
    else
        echo
        echo "===> Package_dir not found, navigating to package_name: $package_name"
        echo
        cd "$package_name"
    fi

    echo
    echo "==================== Building wheel ===================="
    echo

    # wheel creation without isolation
    if ! python -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"; then
        
        echo
        echo "===> Wheel Creation Failed for Python $PYTHON_VERSION (without isolation)"
        echo

        # wheel creation with isolation
        if ! python -m build --wheel --outdir="$CURRENT_DIR/"; then
            echo
            echo "===> Wheel Creation Failed for Python $PYTHON_VERSION"
            echo
            exit 1
        fi
    fi
fi

cd "$CURRENT_DIR"
shopt -s nullglob
wheels=("$CURRENT_DIR"/*.whl)
wheel_count=${#wheels[@]}

# check the wheel count in the current dir
if [ "$wheel_count" -ne 1 ]; then
    echo
    echo "===> ERROR: Expected exactly 1 wheel but found $wheel_count"
    echo
    exit 1
fi

wheel_file="${wheels[0]}"

echo 
echo "==== Running auditwheel repair on: ${wheel_file} ===="
echo 

# location of repaired wheel
WHEELHOUSE="$CURRENT_DIR/wheelhouse"
mkdir -p "$WHEELHOUSE"

# run auditwheel
set +e
audit_output=$(auditwheel repair "$wheel_file" --wheel-dir "$WHEELHOUSE"  --exclude libtensorflow_framework.so.2 --exclude libpython3.11.so.1.0 --exclude libpython3.10.so.1.0 --exclude libpython3.12.so.1.0 --exclude libpython3.13.so.1.0 --exclude libc10.so --exclude libtorch.so --exclude libtorch_cpu.so --exclude libtorch_python.so --exclude libshm.so --exclude libtorchaudio.so --exclude libtorchtext.so --exclude libavutil-ffmpeg.so.54 --exclude libavformat-ffmpeg.so.56 --exclude libswscale-ffmpeg.so.3 --exclude libavcodec-ffmpeg.so.56 --exclude libavformat.so.57 --exclude libswscale.so.4 --exclude libavutil.so.55 --exclude libswscale.so.5 --exclude libavformat.so.58 2>&1)
audit_status=$?
set -e

echo
echo "===> Result of running auditwheel on the wheel:" 
echo
echo "$audit_output"
echo

# error case
if echo "$audit_output" | grep -q "ValueError: Cannot repair wheel"; then
    echo
    echo "===>ERROR: Auditwheel failed to repair wheel: ${wheel_file}"
    echo
    exit 1

# skipped case (no-arch wheels)
elif echo "$audit_output" | grep -q "This does not look like a platform wheel"; then
    
    echo
    echo "===> Auditwheel skipped for: ${wheel_file}"
    echo

    if [[ "$wheel_file" == *any.whl ]]; then
        echo
        echo "===> Pure Python wheel detected. (No-arch wheel)"
        echo
    else
        echo
        echo "===> ERROR: Skipped wheel is not universal i.e(*any.whl)."
        echo
        exit 1
    fi

# success case
elif [ "$audit_status" -eq 0 ]; then
    echo
    echo "===> Auditwheel succeeded for $wheel_file"
    echo

    rm -f "$CURRENT_DIR"/*.whl
    cp "$WHEELHOUSE"/*.whl "$CURRENT_DIR"
    
    echo
    echo "===> Repaired wheel $(basename "$WHEELHOUSE"/*.whl) copied at $CURRENT_DIR"
    echo

# any other case
else
    echo
    echo "===> ERROR: Auditwheel failed."
    echo
    exit 1
fi


cd "$CURRENT_DIR"
wheel_final=(*.whl)

echo
echo "============== Generating sha for: ${wheel_final} =============="
echo

# generate sha256
generate_sha "$BUILD_SCRIPT_PATH" "$PYTHON_VERSION" "$CURRENT_DIR" "$wheel_final"

SHA256_VALUE=$(cat sha256.sha)

echo
echo "=== Post Processing wheel ${wheel_final} with SHA: ${SHA256_VALUE} ==="
echo

# post processing of wheels (Suffix addition, license addition, metadata addition)
if python ${POST_PROCESS_SCRIPT_PATH} ${wheel_final} ${SHA256_VALUE}; then
    echo 
    echo "===> SUCCESS: Wheels post process successfully."
    echo
else
    echo
    echo "===> ERROR: Failed to post process wheels."
    echo
    exit 1  
fi

echo
echo "============ Final wheel: $(ls -t *.whl 2>/dev/null | head -1) ==========="
echo

# Clean up virtual environment
cleanup "$VENV_DIR"

# Remove temporary build script
[ -n "$TEMP_BUILD_SCRIPT_PATH" ] && rm "$CURRENT_DIR/$TEMP_BUILD_SCRIPT_PATH"

exit 0
