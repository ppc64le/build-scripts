 #!/bin/bash -xe
 files_upload_link='https://163.69.91.4:8443/repository/currency-artifacts/docker-details/local/'
 packageName=$(echo $PACKAGE_NAME | tr '[:upper:]' '[:lower:]')
 imageName="icr.io/ppc64le-oss/$packageName-ppc64le:$VERSION"
 url_prefix=$(files_upload_link)${packageName}'-ppc64le/'${VERSION}
 initialChar=${packageName:0:1}
 packageDirPath="$initialChar/$packageName/"
 buildInfoPath=$packageDirPath'build_info.json'
 

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
  echo "Checking for string/pattern match for version in build_info.json"

  if [[ $(jq --arg ver $version '.[$ver]' $configFile) == null ]]; then
    jsonObj=$(cat $configFile)
    # Inline Python code using python3 -c
    result_version=$(python<< END_OF_PYTHON_SCRIPT

    import re

    def find_matching_version(jsonObj, version):
        for entry in jsonObj:
            key = entry
            subKeys = [subKey.strip() for subKey in key.split(',')]
            if version in subKeys:
                version = key
                print (f"BREAK1 {version}")
                return version
            else:
                for subKey in subKeys:
                    regex_str = '^' + subKey.replace(".", "\\.").replace("*", ".*") + '$'
                    regex = re.compile(regex_str)
                    if regex.match(version):
                        version = key
                        print (f"BREAK2 {version}")
                        return version

    input_version = str("$VERSION")
    input_jsonObj = "$jsonObj"
    result_version = find_matching_version(input_jsonObj, input_version)
    print(f"BREAK3 {result_version}")

    END_OF_PYTHON_SCRIPT
    # End of Python script
    )
    
    VERSION=$result_version

  fi

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

echo "export BUILD_SCRIPT=$build_script" > $CUR_DIR/variable.sh
echo "export PKG_DIR_PATH=$packageDirPath" >> $CUR_DIR/variable.sh
echo "export IMAGE_NAME=$imageName" >> $CUR_DIR/variable.sh
echo "export BUILD_DOCKER=$build_docker" >> $CUR_DIR/variable.sh
echo "export VALIDATE_BUILD_SCRIPT=$validate_build_script" >> $CUR_DIR/variable.sh

chmod +x $CUR_DIR/variable.sh
cat $CUR_DIR/variable.sh
cd $CUR_DIR
