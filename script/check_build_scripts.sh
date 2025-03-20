#!/bin/bash

# Fail on any error
set -e

VARIABLE_FILE="script/variable.sh"

CURRENT_BRANCH="${TRAVIS_BRANCH:-master}"

# Fetch modified build scripts
MODIFIED_SCRIPTS=$(git diff --name-only origin/$CURRENT_BRANCH...HEAD -- '*.sh')

# Fetch modified build_info.json files
MODIFIED_JSONS=$(git diff --name-only origin/$CURRENT_BRANCH...HEAD -- '*/build_info.json')

# Exit if no build scripts are modified
if [[ -z "$MODIFIED_SCRIPTS" ]]; then
  echo "No build script modifications detected. Exiting Travis job."
  exit 0
fi

for script in $MODIFIED_SCRIPTS; do
  echo "printing script path $script"
  PACKAGE_DIR=$(dirname "$script")
  BUILD_SCRIPT_NAME=$(basename "$script")
  BUILD_SCRIPT_PATH="$(pwd)/$script"
  BUILD_INFO_FILE="$(pwd)/$PACKAGE_DIR/build_info.json"

  echo "----------------------------------"
  echo "Build Script: $BUILD_SCRIPT_PATH"
  echo "Package Directory: $PACKAGE_DIR"

  tested_on=$(awk -F': ' '/^# Tested on/ {print $2}' "$BUILD_SCRIPT_PATH" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')


  if [[ -z "$tested_on" ]]; then
    tested_on="unknown"
    echo "No '# Tested on:' parameter found in $BUILD_SCRIPT_PATH."
  fi


  # Check if build_info.json is modified
  if echo "$MODIFIED_JSONS" | grep -q "$BUILD_INFO_FILE"; then
    echo "Using modified build_info.json"
    VERSION=$(git show HEAD:"$BUILD_INFO_FILE" | jq -r '.version')
    WHEEL_BUILD=$(git show HEAD:"$BUILD_INFO_FILE" | jq -r '.wheel_build')
    nonRootBuild=$(git show HEAD:"$BUILD_INFO_FILE" | jq -r '.use_non_root_user')

  elif [[ -f "$BUILD_INFO_FILE" ]]; then
    echo "Using existing build_info.json"
    echo "Checking file: $BUILD_INFO_FILE"
    cat "$BUILD_INFO_FILE"  # Debug: Print file content
    
    VERSION=$(jq -r '.version' "$BUILD_INFO_FILE")
    WHEEL_BUILD=$(jq -r '.wheel_build' "$BUILD_INFO_FILE")
    nonRootBuild=$(jq -r '.use_non_root_user' "$BUILD_INFO_FILE")
    echo "Extracted Version: $VERSION"
    echo "Extracted Wheel Build: $WHEEL_BUILD"
    echo "Extracted nonRootbuild: $nonRootBuild"
  else
    echo "No build_info.json found in $PACKAGE_DIR"
    exit 0
  fi

  if [[ "$WHEEL_BUILD" == "false" ]]; then
    echo "wheel_build is set to false. Exiting Travis job."
    exit 0
  fi

  # Append variables to variable.sh
  echo "export PKG_DIR_PATH=$PACKAGE_DIR/" >> "$VARIABLE_FILE"
  echo "export BUILD_SCRIPT=$BUILD_SCRIPT_NAME" >> "$VARIABLE_FILE"
  echo "export VERSION=$VERSION" >> "$VARIABLE_FILE"
  echo "export NON_ROOT_BUILD=$nonRootBuild" >> "$VARIABLE_FILE"
  echo "export TESTED_ON=$tested_on" >> "$VARIABLE_FILE"

  chmod +x script/variable.sh

  # Proceed with further steps
  echo "Processing $PACKAGE_DIR..."
done
