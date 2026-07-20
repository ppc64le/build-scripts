#!/bin/bash -e

validate_build_script=$VALIDATE_BUILD_SCRIPT
cloned_package=$CLONED_PACKAGE

sudo apt update -y && sudo apt install -y jq
GRYPE_VERSION=$(curl -s https://api.github.com/repos/anchore/grype/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
wget https://github.com/anchore/grype/releases/download/$GRYPE_VERSION/grype_${GRYPE_VERSION#v}_linux_ppc64le.tar.gz
tar -xzf grype_${GRYPE_VERSION#v}_linux_ppc64le.tar.gz
chmod +x grype
sudo mv grype /usr/bin 
echo "------------- Installed grype---------------"
grype --version


echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
ls 
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
cd package-cache/wheels


for wheel in *.whl; do
  echo "Processing: $wheel"
  
  base_name="${wheel%.whl}"  # Strip .whl extension
  extract_dir="${base_name}_extract"
  output_json="${base_name}_grype_output.json"


  echo "base name : $base_name"
  echo "extract_dir : $extract_dir"
  echo "output_json : $output_json"
 

  # Unzip the wheel
  unzip -q "$wheel" -d "$extract_dir"
  echo "------------- unzippied wheel ------------------------------"
  ls
  
  
  # Run grype scanner
  echo "------------------------------------------------------------"
  grype "$extract_dir" -o json | jq . > "$output_json"

  # Zip the result
  echo "------------------------- output files ---------------------"
  ls
  echo "------------------------------------------------------------"
  echo "Finished: $wheel"
done
