To build the Cypress docker images:
--------------------------------------

**1. First ensure the storage driver on the docker host is set to overlay2**

cat <<EOT > /etc/docker/daemon.json
{
"storage-driver": "overlay2"
}
EOT
service docker restart

**2. Run a docker container with the following command...**

docker run -it --network host --shm-size=2gb --privileged  -v /var/run/docker.sock:/var/run/docker.sock --name cypress docker.io/ubuntu:22.04 bash

**3. Run the following script in the above container (took 6 hours on our hardware)...**

########################################################################################################################################################  
########################################################################################################################################################  

set -ex

WORK_DIR=$(pwd)  
  
#Install dependencies  
apt-get update -y  
apt-get install -y wget

#download scripts  
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/electron/electron-22.0.3-ubuntu-22.04.sh  
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/cypress/cypress_12.5.1_Ubuntu_22.04.sh  
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/cypress/cypress-docker-images_12.5.1_Ubuntu_22.04.sh  
  
#source electron  
chmod +x electron-22.0.3-ubuntu-22.04.sh  
source ./electron-22.0.3-ubuntu-22.04.sh

#copy electron redistributables  
cd $WORK_DIR && cp $ELECTRON_DIST . && cp $MKSNAPSHOT_DIST .  

#source cypress  
chmod +x cypress_12.5.1_Ubuntu_22.04.sh
source ./cypress_12.5.1_Ubuntu_22.04.sh  

#copy cypress redistributable  
cd $WORK_DIR && cp $CYPRESS_DIST .  

#source cypress docker images  
chmod +x cypress-docker-images_12.5.1_Ubuntu_22.04.sh  
source ./cypress-docker-images_12.5.1_Ubuntu_22.04.sh  

echo "Complete!"  

#######################################################################################################################################################  
#######################################################################################################################################################

**4. List the newly built Cypress docker images in the host**

docker images | grep cypress

