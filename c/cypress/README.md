To build the Cypress docker images:
--------------------------------------

**1. Run a docker container with the following command...**

docker run -it --network host --shm-size=2gb --privileged  -v /var/run/docker.sock:/var/run/docker.sock --name cypress docker.io/ubuntu:22.04 bash

**2. Run the following script in the above container (took 6 hours on our hardware)...**

#######################################################################################################################################################
#######################################################################################################################################################
set -ex

WORK_DIR=`pwd`

#Install dependencies
apt-get update -y
apt-get install -y wget

#source electron
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/electron/electron-22.0.3-ubuntu-22.04.sh
chmod +x electron-22.0.3-ubuntu-22.04.sh
source ./electron-22.0.3-ubuntu-22.04.sh

#copy electron redistributables
cd $WORK_DIR
cp $ELECTRON_DIST .
cp $MKSNAPSHOT_DIST .

#source cypress
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/cypress/cypress-12.5.1-Ubuntu-22.04.sh
chmod +x cypress-12.5.1-Ubuntu-22.04.sh
source ./cypress-12.5.1-Ubuntu-22.04.sh

#copy cypress redistributable
cd $WORK_DIR
cp $CYPRESS_DIST .

#source cypress docker images
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/cypress/cypress-docker-images_12.5.1_Ubuntu_22.04.sh
chmod +x cypress-docker-images_12.5.1_Ubuntu_22.04.sh
source ./cypress-docker-images_12.5.1_Ubuntu_22.04.sh

echo "Complete!"

#######################################################################################################################################################
#######################################################################################################################################################

**3. List the newly built Cypress docker images in the host**

docker images | grep cypress
