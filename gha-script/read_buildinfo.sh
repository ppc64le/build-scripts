 #!/bin/bash -e
 files_upload_link='https://163.69.91.4:8443/repository/currency-artifacts/docker-details/local/'
 package_name=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
 image_name="icr.io/ppc64le-oss/$package_name-ppc64le:$VERSION"
 url_prefix=${files_upload_link}${package_name}'-ppc64le/'${VERSION}
 initial_char=${package_name:0:1}
 package_dirpath="$initial_char/$package_name/"
 buildinfo_path=$package_dirpath'build_info.json'
 match_version=$VERSION
 

if [ -f $buildinfo_path ]; then
  echo $package_dirpath 'exists'
else
  package_dirpath="$initial_char/$PACKAGE_NAME/"
  echo "Correct package_dirpath is $package_dirpath"
fi

CUR_DIR=$(pwd)
cd $package_dirpath
echo "printing the list of contents"
pwd
ls -ltr
config_file='build_info.json'
if [ -f $config_file ]; then

  jsonObj=$config_file
  build_script=$(jq .build_script $jsonObj)
  
  if $(jq 'has("use_non_root_user")' $jsonObj); then    
    nonRootBuild=$(jq .use_non_root_user $jsonObj)
  fi
  
  #default build_docker=true
  build_docker=true
  if $(jq 'has("docker_build")' $jsonObj); then
    build_docker=$(jq .docker_build $jsonObj)
  fi
  
  #default validate_build_script=true
  validate_build_script=true
  if $(jq 'has("validate_build_script")' $jsonObj); then
    validate_build_script=$(jq .validate_build_script $jsonObj)
  fi
  echo "Checking for string/pattern match for version in build_info.json"

  if [[ $(jq --arg ver $VERSION '.[$ver]' $config_file) == null ]]; then
    # Using python script to find matched version string/key in build_info.json for version passed 
    match_version=$(python $CUR_DIR/gha-script/match_version_buildinfo.py)
    echo "match_version = $match_version"

  fi
  #Getting specific build_script name for version
  if [[ $(jq --arg ver "$match_version" '.[$ver]' $config_file) != null ]]; then
    if [[ $(jq -r --arg ver "$match_version" '.[$ver].build_script' $config_file) != null ]]; then
      build_script=$(jq -r --arg ver "$match_version" '.[$ver].build_script' $config_file)
    fi

    if [[ $(jq -r --arg ver "$match_version" '.[$ver].base_docker_image' $config_file) != null ]]; then
      basename=$(jq -r --arg ver "$match_version" '.[$ver].base_docker_image' $config_file)
    fi
  
    if [[ $(jq -r --arg ver "$match_version" '.[$ver].base_docker_variant' $config_file) != null ]]; then
      variant_str=$(jq -r --arg ver "$match_version" '.[$ver].base_docker_variant' $config_file)
      case "$variant_str" in
        "rhel")
          variant=1
          ;;
        "ubuntu")
          variant=2
          ;;
        "alpine")
          variant=3
          ;;
        *)
          echo "No valid distro variant, picking default one"
          variant=1
          ;;
      esac
   fi
  fi
fi

# Below code is used to get the tested on parameter value from the build script
build_script_with_quotes=$build_script
stripped_build_script=$(echo "$build_script_with_quotes" | sed 's/"//g')
echo $stripped_build_script
if [ -f $stripped_build_script ]; then
  echo "build script found"
  while IFS= read -r line; do
      # Check if the line starts with '# Tested on'
      if [[ "$line" == "# Tested on"* ]]; then
          # Extract the value after the first colon
          tested_on=$(echo "$line" | cut -d ':' -f 2- | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
          break
      fi
  done < "$stripped_build_script"  # Use input redirection from the file
  echo "Tested on value: $tested_on"
fi


echo "export VERSION=$VERSION" > $CUR_DIR/variable.sh
echo "export BUILD_SCRIPT=$build_script" >> $CUR_DIR/variable.sh
echo "export PKG_DIR_PATH=$package_dirpath" >> $CUR_DIR/variable.sh
echo "export IMAGE_NAME=$image_name" >> $CUR_DIR/variable.sh
#echo "export BUILD_DOCKER=$build_docker" >> $CUR_DIR/variable.sh
#echo "export VALIDATE_BUILD_SCRIPT=$validate_build_script" >> $CUR_DIR/variable.sh
echo "export VARIANT=$variant" >> $CUR_DIR/variable.sh
echo "export BASENAME=$basename" >> $CUR_DIR/variable.sh
echo "export NON_ROOT_BUILD=$nonRootBuild" >> $CUR_DIR/variable.sh
echo "export TESTED_ON=$tested_on" >> $CUR_DIR/variable.sh

chmod +x $CUR_DIR/variable.sh
cat $CUR_DIR/variable.sh
cd $CUR_DIR
