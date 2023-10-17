 #!/bin/bash -xe

sudo apt update -y && sudo apt-get install file -y
docker pull registry.access.redhat.com/ubi8/ubi:8.7
pip3 install --upgrade requests
pip3 install --upgrade docker

echo "Running build script execution in background for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" " 
echo "*************************************************************************************"
      
python3 script/validate_builds_currency.py "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" > build_log &

SCRIPT_PID=$!
while ps -p $SCRIPT_PID > /dev/null
do 
  echo "$SCRIPT_PID is running"
  sleep 100
done
wait $SCRIPT_PID
my_pid_status=$?
if [ $my_pid_status != 0 ]
then
    echo "Script execution failed for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "
    echo "*************************************************************************************"
    cat build_log
    exit 1
else
    echo "Script execution completed successfully for "$PKG_DIR_PATH$BUILD_SCRIPT" "$VERSION" "
    echo "*************************************************************************************"
    cat build_log
fi
exit 0

