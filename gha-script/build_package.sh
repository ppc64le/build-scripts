 #!/bin/bash -e

sudo apt update -y && sudo apt-get install file -y
#pip3 install --upgrade requests
pip3 install --force-reinstall -v "requests==2.31.0"
pip3 install --upgrade docker

echo "Running build script execution in background for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" " 
echo "*************************************************************************************"

docker_image=""

# the below function is used for building a custom docker image, it will be called only when non root user build is set to true.
# function accepts one argument, which is the base image value.
docker_build_non_root() {
  echo "building docker image for non root user build"
  docker build --build-arg BASE_IMAGE="$1" -t docker_non_root_image -f gha-script/dockerfile_non_root .
  docker_image="docker_non_root_image"
}

#Below conditions are used to select the base image based on the 2 flags, tested_on and non_root_build. A docker_build_non_root function is called when non root build is true.
if [[ "$TESTED_ON" == UBI:9* || "$TESTED_ON" == UBI9* ]];
then
    ubi_version=$(echo "$TESTED_ON" | grep -oE '[0-9]+\.[0-9]+')
    docker pull registry.access.redhat.com/ubi9/ubi:$ubi_version
    docker_image="registry.access.redhat.com/ubi9/ubi:$ubi_version"
    if [[ "$NON_ROOT_BUILD" == "true" ]];
    then
        docker_build_non_root "registry.access.redhat.com/ubi9/ubi:$ubi_version"
    fi
else
    docker pull registry.access.redhat.com/ubi8/ubi:8.7
    docker_image="registry.access.redhat.com/ubi8/ubi:8.7"
    if [[ "$NON_ROOT_BUILD" == "true" ]];
    then
        docker_build_non_root "registry.access.redhat.com/ubi8/ubi:8.7"
    fi  
fi

# python3 script/validate_builds_currency.py "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "$docker_image" > build_log &

# SCRIPT_PID=$!
# while ps -p $SCRIPT_PID > /dev/null
# do 
#   echo "$SCRIPT_PID is running"
#   sleep 100
# done
# wait $SCRIPT_PID
python3 gha-script/validate_builds_currency.py "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "$docker_image" 2>&1 | tee build_log
my_pid_status=${PIPESTATUS[0]}

build_size=$(stat -c %s build_log)

if [ $my_pid_status != 0 ];
then
    echo "Script execution failed for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "
    echo "*************************************************************************************"
    if [ $build_size -lt 1800000 ];
    then
       cat build_log
    else
       tail -100 build_log
    fi
    exit 1
else
    echo "Script execution completed successfully for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "
    echo "*************************************************************************************"
    if [ $build_size -lt 1800000 ];
    then
       cat build_log
    else
       tail -100 build_log
    fi    
fi
exit 0
