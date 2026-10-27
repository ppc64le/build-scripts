#!/bin/bash -e

cloned_package=$CLONED_PACKAGE

# Use pre-installed grype from the cached artifact.
# $GRYPE_BIN is set by the workflow (points to scan-tools-bin/grype).
if [ -z "$GRYPE_BIN" ]; then
  echo "Error: GRYPE_BIN environment variable not set"
  exit 1
fi

cd package-cache

echo "------------- Using cached grype ---------------"
$GRYPE_BIN version
echo "Executing Grype scanner"
sudo $GRYPE_BIN -q -o cyclonedx-json dir:${cloned_package} > grype_source_sbom_results.json
sudo $GRYPE_BIN -q -o json dir:${cloned_package} > grype_source_vulnerabilities_results.json
