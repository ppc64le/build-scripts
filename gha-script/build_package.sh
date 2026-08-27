#!/bin/bash -e

sudo apt update -y && sudo apt-get install file -y
#pip3 install --upgrade requests
pip3 install --force-reinstall -v "requests==2.31.0"
pip3 install --upgrade docker

echo "Running build script execution in background for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" " 
echo "*************************************************************************************"

docker_image=""

# Builds a custom non-root wrapper image on top of the given base image.
# Sets docker_image to "docker_non_root_image" on success.
docker_build_non_root() {
  echo "building docker image for non root user build"
  docker build --build-arg BASE_IMAGE="$1" -t docker_non_root_image -f gha-script/dockerfile_non_root .
  docker_image="docker_non_root_image"
}

# Resolves the correct UBI registry image from the TESTED_ON string and
# sets the global docker_image variable.  Supports UBI8, UBI9, UBI10+.
# The TESTED_ON value is normalised before parsing so all of the following
# formats work:  "UBI:9.3"  "UBI 9.3"  "ubi9.3"  "UBI: 9.3"  "UBI 10"
resolve_docker_image() {
  local raw="$1"
  local upper
  upper=$(echo "$raw" | tr '[:lower:]' '[:upper:]')

  # Collapse "UBI : 9.3" / "UBI:9.3" / "UBI 9.3" / "UBI9.3" -> "UBI9.3"
  # Uses sed only  -  no grep -P (absent on ppc64le runners).
  local norm
  norm=$(echo "$upper" | sed 's/UBI[[:space:]]*[: ][[:space:]]*/UBI/g')

  # Extract the major UBI version integer immediately after "UBI"
  local major
  major=$(echo "$norm" | sed 's/.*UBI\([0-9][0-9]*\).*/\1/')
  case "$major" in
    ''|*[!0-9]*) major="" ;;
  esac

  if [ -z "$major" ]; then
    echo "ERROR: Cannot determine UBI major version from TESTED_ON='$raw'"
    exit 1
  fi

  # Extract the full version string e.g. "9.3", "10.3" (first X.Y found)
  local full
  full=$(echo "$upper" | grep -oE '[0-9]+\.[0-9]+' | head -1)

  if [ -z "$full" ]; then
    # No minor version supplied  -  use per-major defaults
    case "$major" in
      8)  full="8.7"  ;;
      9)  full="9.3"  ;;
      10) full="10.0" ;;
      *)  full="${major}.0" ;;
    esac
    echo "WARNING: No minor version in TESTED_ON='$raw', defaulting to UBI ${full}"
  fi

  # Select the registry image by major version
  case "$major" in
    8)
      docker_image="registry.access.redhat.com/ubi8/ubi:${full}"
      ;;
    9)
      docker_image="registry.access.redhat.com/ubi9/ubi:${full}"
      ;;
    10)
      docker_image="registry.access.redhat.com/ubi10/ubi:${full}"
      ;;
    *)
      echo "ERROR: Unsupported UBI major version '${major}' in TESTED_ON='$raw'"
      exit 1
      ;;
  esac

  echo " Resolved Docker image: $docker_image  (TESTED_ON='$raw')"

  if [[ "$NON_ROOT_BUILD" == "true" ]]; then
    docker_build_non_root "$docker_image"
  fi
}

resolve_docker_image "$TESTED_ON"

# Only pull images that come from a remote registry.
# docker_non_root_image is built locally by docker_build_non_root() and
# does not exist in any registry, so pulling it would always fail.
if [[ "$docker_image" != "docker_non_root_image" ]]; then
  docker pull "$docker_image"
fi


python3 gha-script/validate_builds_currency.py "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "$docker_image" 2>&1 | tee build_log
my_pid_status=${PIPESTATUS[0]}

build_size=$(stat -c %s build_log)

if [ $my_pid_status != 0 ];
then
    echo "Script execution failed for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "
    echo "*************************************************************************************"
    exit 1
else
    echo "Script execution completed successfully for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "
    echo "*************************************************************************************"  
fi
exit 0
