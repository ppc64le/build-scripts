 #!/bin/bash -xe

sudo apt update -y && sudo apt-get install file -y
docker pull registry.access.redhat.com/ubi8/ubi:8.7
pip3 install requests
pip3 install docker

echo "Running build script execution in background for "$PKG_DIR_PATH/$BUILD_SCRIPT" "$VERSION" " 
      
python3 script/validate_builds.py "$PKG_DIR_PATH/$BUILD_SCRIPT" "$VERSION" &

SCRIPT_PID=$!
while ps -p $SCRIPT_PID > /dev/null
do 
  echo "$SCRIPT_PID is running"
  sleep 300
done
wait $SCRIPT_PID
my_pid_status=$?
if [ $? != 0 ]
then
    echo "Script execution failed for "$PKG_DIR_PATH/$BUILD_SCRIPT" "$VERSION" "
    exit 1
fi
