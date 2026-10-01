#!/usr/bin/env bash
set -euo pipefail

RUNTIME="${1:?PowerCore runtime required}"
PACKAGE_NAME="${2:?package name required}"
WORKSPACE_DIR="${3:-v2-scan-workspace}"
POWERCORE_BUILD_SCRIPTS="${POWERCORE_BUILD_SCRIPTS:-/home/powercore/build-scripts-v2}"

echo "--- V2 scan workspace inputs ---"
echo "RUNTIME=${RUNTIME}"
echo "PACKAGE_NAME=${PACKAGE_NAME}"
echo "WORKSPACE_DIR=${WORKSPACE_DIR}"
echo "POWERCORE_BUILD_SCRIPTS=${POWERCORE_BUILD_SCRIPTS}"

REQUEST_DIR=$(sudo -u powercore find "$RUNTIME" -type d -name 'BRequest_*' 2>/dev/null | sort | tail -1)
if [ -z "$REQUEST_DIR" ]; then
  echo "ERROR: no BRequest directory found under $RUNTIME" >&2
  echo "Available runtime directories:" >&2
  sudo find "$RUNTIME" -maxdepth 3 -type d 2>/dev/null | sort >&2 || true
  exit 1
fi

rm -rf "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR/package-cache" "$WORKSPACE_DIR/wheels" "$WORKSPACE_DIR/image" "$WORKSPACE_DIR/metadata"
echo "REQUEST_DIR=${REQUEST_DIR}"

while IFS= read -r wheel; do
  [ -z "$wheel" ] && continue
  sudo cp -f "$wheel" "$WORKSPACE_DIR/wheels/$(basename "$wheel")"
done < <(sudo find "$REQUEST_DIR" -type f -name '*.whl' 2>/dev/null)

PACKAGE_JSON=$(sudo find "$REQUEST_DIR" -type f -name 'package.json' -print -quit 2>/dev/null)
if [ -n "$PACKAGE_JSON" ]; then
  sudo cp -f "$PACKAGE_JSON" "$WORKSPACE_DIR/metadata/package.json"
fi

while IFS= read -r metadata_file; do
  [ -z "$metadata_file" ] && continue
  sudo cp -f "$metadata_file" "$WORKSPACE_DIR/metadata/$(basename "$metadata_file")"
done < <(sudo find "$REQUEST_DIR" -type f \( -name 'validation_summary.json' -o -name 'artifacts_summary.json' -o -name 'post_process_summary.json' \) 2>/dev/null)

SOURCE_DIR=$(sudo find "$REQUEST_DIR" -type d \( -name src -o -name source -o -name "$PACKAGE_NAME" \) 2>/dev/null | head -1 || true)
if [ -z "$SOURCE_DIR" ]; then
  SOURCE_DIR=$(sudo find "$POWERCORE_BUILD_SCRIPTS" -type d -path "*/${PACKAGE_NAME}" 2>/dev/null | head -1 || true)
  if [ -n "$SOURCE_DIR" ]; then
    echo "Using package directory for source scan: $SOURCE_DIR"
  fi
fi
if [ -n "$SOURCE_DIR" ]; then
  mkdir -p "$WORKSPACE_DIR/package-cache/source"
  sudo tar -C "$SOURCE_DIR" -cf - . | tar -C "$WORKSPACE_DIR/package-cache/source" -xf -
else
  echo "WARNING: no source directory found in $REQUEST_DIR or $POWERCORE_BUILD_SCRIPTS" >&2
fi
printf 'export CLONED_PACKAGE=source\n' > "$WORKSPACE_DIR/package-cache/scanner-env.sh"

cat > "$WORKSPACE_DIR/package-cache/variable.sh" <<EOF
export PACKAGE_NAME="$PACKAGE_NAME"
export VALIDATE_BUILD_SCRIPT=true
export BUILD_DOCKER=true
EOF

IMAGE_TAR=$(sudo find "$REQUEST_DIR" -type f -name 'image.tar' -print -quit 2>/dev/null)
if [ -n "$IMAGE_TAR" ]; then
  sudo cp -f "$IMAGE_TAR" "$WORKSPACE_DIR/image/image.tar"
fi

printf 'REQUEST_DIR=%s\n' "$REQUEST_DIR" > "$WORKSPACE_DIR/metadata/request.env"
printf 'POWERCORE_BUILD_SCRIPTS=%s\n' "$POWERCORE_BUILD_SCRIPTS" >> "$WORKSPACE_DIR/metadata/request.env"
printf 'PACKAGE_NAME=%s\n' "$PACKAGE_NAME" >> "$WORKSPACE_DIR/metadata/request.env"
printf 'SOURCE_PRESENT=%s\n' "$(test -d "$WORKSPACE_DIR/package-cache/source" && echo true || echo false)" >> "$WORKSPACE_DIR/metadata/request.env"
printf 'WHEEL_PRESENT=%s\n' "$(find "$WORKSPACE_DIR/wheels" -name '*.whl' -print -quit | grep -q . && echo true || echo false)" >> "$WORKSPACE_DIR/metadata/request.env"
printf 'IMAGE_PRESENT=%s\n' "$(test -f "$WORKSPACE_DIR/image/image.tar" && echo true || echo false)" >> "$WORKSPACE_DIR/metadata/request.env"
