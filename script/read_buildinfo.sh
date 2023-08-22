 #!/bin/bash -xe
 files_upload_link='https://163.69.91.4:8443/repository/currency-artifacts/docker-details/local/'
 packageName=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
 imageName="icr.io/ppc64le-oss/$packageName-ppc64le:$VERSION"
 url_prefix=$(files_upload_link)${packageName}'-ppc64le/'${VERSION}
 initialChar=${packageName:0:1}
 packageDirPath="$initialChar/$packageName/"
 buildInfoPath=$packageDirPath'build_info.json'
 match_version=$VERSION
 

if [ -f $buildInfoPath ]; then
  echo $packageDirPath 'exists'
else
  packageDirPath="$initialChar/$PACKAGE_NAME"
  echo "Correct packageDirPath is $packageDirPath"
fi

CUR_DIR=$(pwd)
cd $packageDirPath

configFile='build_info.json'
if [ -f $configFile ]; then

  jsonObj=$configFile
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

  if [[ $(jq --arg ver $VERSION '.[$ver]' $configFile) == null ]]; then
    # Inline Python code using python3 -c
    # result_version=$(python $CUR_DIR/script/parse_buildinfo.py)
    match_version=$(python $CUR_DIR/script/parse_buildinfo.py)
    echo "match_version = $match_version"
    # VERSION=$match_version

  fi
  #Getting specific build_script name for version
  if [[ $(jq --arg ver "$match_version" '.[$ver]' $configFile) != null ]]; then
    if [[ $(jq -r --arg ver "$match_version" '.[$ver].build_script' $configFile) != null ]]; then
      build_script=$(jq -r --arg ver "$match_version" '.[$ver].build_script' $configFile)
    fi

    if [[ $(jq -r --arg ver "$match_version" '.[$ver].dir' $configFile) != null ]]; then
      docker_build_dir=$(jq -r --arg ver "$match_version" '.[$ver].dir' $configFile)
    fi

    if [[ $(jq -r --arg ver "$match_version" '.[$ver].patches' $configFile) != null ]]; then
      patches=$(jq -r --arg ver "$match_version" '.[$ver].patches' $configFile)
    fi
    
    if [[ $(jq -r --arg ver "$match_version" '.[$ver].args' $configFile) != null ]]; then
      args=$(jq -r --arg ver "$match_version" '.[$ver].args' $configFile)
    fi
    
    if [[ $(jq -r --arg ver "$match_version" '.[$ver].base_docker_image' $configFile) != null ]]; then
    baseName=$(jq -r --arg ver "$match_version" '.[$ver].base_docker_image' $configFile)
    fi
  
    if [[ $(jq -r --arg ver "$match_version" '.[$ver].base_docker_variant' $configFile) != null ]]; then
    variant_str=$(jq -r --arg ver "$match_version" '.[$ver].base_docker_variant' $configFile)
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


echo "export VERSION=$VERSION" > $CUR_DIR/variable.sh
echo "export BUILD_SCRIPT=$build_script" >> $CUR_DIR/variable.sh
echo "export PKG_DIR_PATH=$packageDirPath" >> $CUR_DIR/variable.sh
echo "export IMAGE_NAME=$imageName" >> $CUR_DIR/variable.sh
echo "export BUILD_DOCKER=$build_docker" >> $CUR_DIR/variable.sh
echo "export VALIDATE_BUILD_SCRIPT=$validate_build_script" >> $CUR_DIR/variable.sh
echo "export DOCKER_BUILD_DIR=$docker_build_dir" >> $CUR_DIR/variable.sh
echo "export ARGS=$args" >> $CUR_DIR/variable.sh
echo "export PATCHES=$patches" >> $CUR_DIR/variable.sh

chmod +x $CUR_DIR/variable.sh
cat $CUR_DIR/variable.sh
cd $CUR_DIR
