#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE

echo "----------Installing dependencies -----------------"
sudo apt update -y && sudo apt install -y file git python3.12 python3.12-venv python3-pip python3.12-dev build-essential unzip patch wget tar libffi-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev libicu-dev pkg-config

echo "----------Installed dependencies -----------------"
git clone https://github.com/nexB/scancode-toolkit.git
cd scancode-toolkit
git checkout v32.4.0
echo "-------------- Create venv ------------------"
python --version
echo "========================================="
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
cd package-cache/wheels


for wheel in *.whl; do
  echo "Processing: $wheel"
  
  base_name="${wheel%.whl}"  # Strip .whl extension
  extract_dir="${base_name}_extract"
  output_json="${base_name}_output.json"


  echo "base name : $base_name"
  echo "extract_dir : $extract_dir"
  echo "output_json : $output_json"
 

  # Unzip the wheel
  unzip -q "$wheel" -d "$extract_dir"
  echo "------------- unzippied wheel ------------------------------"
  ls
  
  
  # Run scancode
  echo "------------------------------------------------------------"
   ../../scancode-toolkit/venv/bin/scancode --license --package --json-pp "$output_json" "$extract_dir"

  # Zip the result
  echo "------------------------- output files ---------------------"
  ls
  echo "------------------------------------------------------------"
  echo "Finished: $wheel"
done
