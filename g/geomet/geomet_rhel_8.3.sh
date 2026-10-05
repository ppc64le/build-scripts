#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : geomet
# Version       : 0.3.1
# Source repo   : https://github.com/geomet/geomet
# Tested on     : RHEL 8.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : BulkPackageSearch Automation <sethp@us.ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: geomet_rhel_8.3.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="geomet"
PACKAGE_VERSION="${1:-0.3.1}"  # Updated from 0.1.0 (not available, >5 years old)
PACKAGE_URL="https://github.com/geomet/geomet"
PACKAGE_AVAILABLE_TAGS="1.1.0,1.0.0,0.3.1"  # Available git tags for fallback testing

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc gcc-c++ git libffi libffi-devel make ncurses python2 python2-devel python3 python3-devel python3-pytest python38 python38-devel python39 python39-devel sqlite sqlite-devel sqlite-libs"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# OS_NAME=`python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])"`
# SOURCE=Github
# pip3 install -r /home/tester/output/requirements.txt
# pip3 freeze > /home/tester/output/available_packages.txt
# PACKAGE_INFO=`cat available_packages.txt | grep $PACKAGE_NAME`
# if ! test -z "$PACKAGE_INFO"; then
# 	SOURCE="Distro"
# function build_test_with_python2(){
# 	SOURCE="Python 2.7"
# if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
#     build_test_with_python2

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
