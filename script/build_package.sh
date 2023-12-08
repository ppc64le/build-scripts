 #!/bin/bash -e

sudo apt update -y && sudo apt-get install file -y
docker pull registry.access.redhat.com/ubi8/ubi:8.7
pip3 install --upgrade requests
pip3 install --upgrade docker

echo "Running build script execution in background for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" " 
echo "*************************************************************************************"

docker_image="registry.access.redhat.com/ubi8/ubi:8.7"
if [ "$NON_ROOT_BUILD" == "true" ];
then
    echo "building docker image for non root user build"
    docker build -t docker_non_root_image -f script/dockerfile_non_root .
    docker_image="docker_non_root_image"
fi

python3 script/validate_builds_currency.py "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "$docker_image" > build_log &

SCRIPT_PID=$!
while ps -p $SCRIPT_PID > /dev/null
do 
  echo "$SCRIPT_PID is running"
  sleep 100
done
wait $SCRIPT_PID
my_pid_status=$?
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

