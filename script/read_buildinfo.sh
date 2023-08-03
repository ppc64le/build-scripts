 #!/bin/bash -xe
 files_upload_link='https://163.69.91.4:8443/repository/currency-artifacts/docker-details/local/'
 packageName=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
 imageName="icr.io/ppc64le-oss/$packageName-ppc64le:$VERSION"
 url_prefix=$(files_upload_link)${packageName}'-ppc64le/'${VERSION}
 initialChar=${packageName:0:1}
 packageDirPath="$initialChar/$packageName"
 buildInfoPath=$packageDirPath'build_info.json'
 


if [ -f $buildInfoPath ]; then
  echo $packageDirPath 'exists'
else
  packageDirPath="$initialChar/$PACKAGE_NAME"
  echo "Correct packageDirPath is $packageDirPath"
fi
CUR_DIR=$(pwd)
cd $packageDirPath;

configFile='build_info.json'
if [ -f $configFile ]; then

  jsonObj=$configFile
  build_script=$(jq .build_script $jsonObj)

  echo -n $build_script | tee $(results.build_script.path)
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
  # TODO: convert below to shell script
  #if (jsonObj[version] == null) {
  #    OUTERLOOP:
  #    for (def entry : jsonObj) {
  #        key = entry.key
  #        def subKeys = key.split(',')
  #        subKeys = subKeys.collect {it.trim()}
  #        if (subKeys.contains(version)) {
  #            version = key
  #            break
  #        } else {
  #            for(def subKey : subKeys) { 
  #        def regex_str = '^' + subKey + '$'
  #        def regex = ~regex_str
  #        if (version =~ regex) {
  #                    version = key
  #                    break OUTERLOOP
  #                }
  #            }
  #        }
  #    }
  #}
  if [[ $(jq --arg ver $VERSION '.[$ver]' $configFile) != null ]] && 
    [[ $(jq -r --arg ver $VERSION '.[$ver].base_docker_image' $configFile) != null ]]; then
    baseName=$(jq -r --arg ver $VERSION '.[$ver].base_docker_image' $configFile)
  fi
  if [[ $(jq --arg ver $VERSION '.[$ver]' $configFile) != null ]] && 
    [[ $(jq -r --arg ver $VERSION '.[$ver].base_docker_variant' $configFile) != null ]]; then
    variant_str=$(jq -r --arg ver $VERSION '.[$ver].base_docker_variant' $configFile)
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

echo "BUILD_SCRIPT=$build_script" > $CUR_DIR/variable.sh
echo "PKG_DIR_PATH=$packageDirPath" >> $CUR_DIR/variable.sh
echo "IMAGE_NAME=$imageName" >> $CUR_DIR/variable.sh
echo "BUILD_DOCKER=$build_docker" >> $CUR_DIR/variable.sh
echo "VALIDATE_BUILD_SCRIPT=$validate_build_script" >> $CUR_DIR/variable.sh

chmod +x $CUR_DIR/variable.sh
cat $CUR_DIR/variable.sh
cd $CUR_DIR
