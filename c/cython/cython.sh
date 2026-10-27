#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cython
# Version       : 0.29.36
# Source repo   : https://github.com/cython/cython/
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: cython_ubi_9.6.sh
# -----------------------------------------------------------------------------
# WARNING: VERSION NOT CONFIRMED IN PACKAGING AUTHORITY
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cython"
PACKAGE_VERSION="${1:-0.29.36}"
PACKAGE_URL="https://github.com/cython/cython/"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel.ppc64le sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Custom test command (extracted from original script)
custom_test_command() {
    # TODO: Review and update test commands
    (python3 -m tox -e py39) && test_status=0 || test_status=$?
}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# PACKAGE_DIR=cython
# pip3 install pytest tox nox
# export PATH=$PATH:/usr/local/bin/
# export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
# export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
# OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
# SOURCE=Github
# if ! command -v rustc &> /dev/null
#     wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
#     tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
#     cd rust-1.75.0-powerpc64le-unknown-linux-gnu
#     sudo ./install.sh
#     export PATH=$HOME/.cargo/bin:$PATH
#     rustc -V
#     cargo -V
#     cd ../
# if [[ "$PACKAGE_URL" == *github.com* ]]; then
#     if [ -d "$PACKAGE_DIR" ]; then
#         cd "$PACKAGE_DIR" || exit
#         if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
#         cd "$PACKAGE_DIR" || exit
#         git checkout "$PACKAGE_VERSION" || exit
#     if [ -d "$PACKAGE_DIR" ]; then
#         cd "$PACKAGE_DIR" || exit
#         if ! curl -L "$PACKAGE_URL" -o "$PACKAGE_DIR.tar.gz"; then
#         mkdir "$PACKAGE_DIR"
#         if ! tar -xzf "$PACKAGE_DIR.tar.gz" -C "$PACKAGE_DIR" --strip-components=1; then
#         cd "$PACKAGE_DIR" || exit
# test_status=1  # 0 = success, non-zero = failure
# if ls */test_*.py > /dev/null 2>&1 && [ $test_status -ne 0 ]; then
#     echo "Running pytest..."
#     (python3 -m pytest) && test_status=0 || test_status=$?
# if [ -f "tox.ini" ] && [ $test_status -ne 0 ]; then
#     echo "Running tox..."
#     (python3 -m tox -e py39) && test_status=0 || test_status=$?
# if [ -f "noxfile.py" ] && [ $test_status -ne 0 ]; then
#     echo "Running nox..."
#     (python3 -m nox) && test_status=0 || test_status=$?
# if [ $test_status -eq 0 ]; then

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
