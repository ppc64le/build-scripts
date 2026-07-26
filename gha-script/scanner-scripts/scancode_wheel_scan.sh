#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE

echo "----------Installing dependencies -----------------"
sudo apt update -y && sudo apt install -y file git python3.12 python3.12-venv python3-pip python3.12-dev build-essential unzip patch wget tar libffi-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev libicu-dev pkg-config

echo "----------Installed dependencies -----------------"
# scancode-toolkit source is fetched once by fetch_scancode_toolkit.sh in install_scan_tools job
# and distributed to all wheel_build jobs as a GHA artifact (scancode-toolkit-src.tar.gz).
# The directory is extracted by the workflow before this script runs, so the clone below
# is a safety fallback only and should not be reached under normal conditions.
SCANCODE_VERSION="v32.4.0"
if [ ! -d "scancode-toolkit" ]; then
  echo "[WARN] scancode-toolkit directory not found. Falling back to git clone..."
  git clone https://github.com/nexB/scancode-toolkit.git
fi
cd scancode-toolkit
git checkout $SCANCODE_VERSION
echo "-------------- Create venv ------------------"
python3.12 -m venv venv
source venv/bin/activate
python3.12 -m pip install --upgrade pip setuptools wheel typecode pyahocorasick

echo "--------------- Apply changes ----------------"
sed -i '/typecode\[full\] >= 30\.0\.1/s/^/    # /' setup.cfg
sed -i '/extractcode\[full\] >= 31\.0\.0/s/^/    # /' setup.cfg
sed -i '/typecode\[full\] >= 30\.0\.0/s/^/    # /' setup.cfg

echo "------------- Install scancode-toolkit ---------------"
python3.12 -m pip install -e .
python3.12 -m pip install click==8.0.4
echo "------------- scancode version ---------------"
scancode --version

echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
cd ..
ls
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

# Wheels are built into the workspace root by build_wheels.sh
WHEEL_DIR=$(pwd)

echo "Looking for wheels in: $WHEEL_DIR"
ls "$WHEEL_DIR"/*.whl 2>/dev/null || { echo "No .whl files found in $WHEEL_DIR"; exit 1; }

for wheel in "$WHEEL_DIR"/*.whl; do
  echo "Processing: $wheel"

  base_name=$(basename "${wheel%.whl}")
  extract_dir="${WHEEL_DIR}/${base_name}_extract"
  output_json="${WHEEL_DIR}/${base_name}_output.json"

  echo "base name : $base_name"
  echo "extract_dir : $extract_dir"
  echo "output_json : $output_json"

  # Unzip the wheel
  unzip -q "$wheel" -d "$extract_dir"
  echo "------------- unzipped wheel ------------------------------"

  # Run scancode
  echo "------------------------------------------------------------"
  scancode --license --package --json-pp "$output_json" "$extract_dir"

  # Cleanup extract dir to save space
  rm -rf "$extract_dir"

  echo "------------------------- output files ---------------------"
  ls "$WHEEL_DIR"/*.json 2>/dev/null || true
  echo "------------------------------------------------------------"
  echo "Finished: $wheel"
done
