#!/bin/bash -e

image_name=$IMAGE_NAME
build_docker=$BUILD_DOCKER

# Use pre-installed grype from the cached artifact.
# $GRYPE_BIN is set by the workflow (points to scan-tools-bin/grype).
if [ -z "$GRYPE_BIN" ]; then
  echo "Error: GRYPE_BIN environment variable not set"
  exit 1
fi

if [ $build_docker == true ]; then
         echo "------------- Using cached grype ---------------"
         $GRYPE_BIN version
         echo "Executing grype scanner"
         sudo $GRYPE_BIN -q -s AllLayers -o cyclonedx-json ${image_name} > grype_image_sbom_results.json
         sudo $GRYPE_BIN -q -s AllLayers -o json ${image_name} > grype_image_vulnerabilities_results.json
fi
