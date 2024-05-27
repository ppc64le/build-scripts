To build and test metricbeat on ubi9.3 ---------------------------------------------------------------------

Skipping "TestDbusEnvConnection" test in metricbeat/module/system/service/service_unit_test.go file.

This test is passing locally where you need below environment.

1. Install docker
   1. Create and start container with below command :

   docker run -t -d --network host --privileged --shm-size=3gb --name <container-name> registry.access.redhat.com/ubi9/ubi:9.3 /usr/sbin/init

   docker exec -it <container-name> bash

   2.Install docker inside container
   dnf install -y yum-utils device-mapper-persistent-data lvm2
   yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo docker-compose-plugin
   dnf install -y docker-ce docker-ce-cli containerd.io
   systemctl enable docker
   systemctl start docker

2. Start dbus-daemon
   
   yum install -y dbus dbus-daemon procps-ng
   mkdir -p /run/dbus
   dbus-daemon --system --fork
   ls -l /var/run/dbus/system_bus_socket
   dbus-daemon --session --print-address --fork
   export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/var/run/dbus/system_bus_socket

3. Create non-root user with sudo previleges and then run the ubi9.3 script


To build and test metricbeat on ubi8.7 ---------------------------------------------------------------------

1.Run the container with  --privileged flag and install docker inside the container, as docker is required to run integration tests.
docker run --name metricbeat --privileged -dit registry.access.redhat.com/ubi8/ubi  /usr/sbin/init
docker exec -it metricbeat bash

2.Login to docker using docker credentials.

3.Run the build script for metricbeat.

4.Two unit tests are failing as the testing data used is hardcoded for intel:https://github.com/elastic/beats/blob/main/metricbeat/module/system/core/_meta/data.json

5.The patch file replaces elasticsearch,kibana, metricbeat and prometheus images with images that have Power support.

6.The build script has steps to build the 'metricbeat' image which is required to execute the integration tests. Link to the Dockerfile used:https://github.com/elastic/beats/blob/main/metricbeat/Dockerfile

7.The build script also has command to pull the v2.40.1 of prometheus image loaclly as we cannot login to docker in the virtual environment created by mage target.

8.This build script also creates a virtual environment using 'make' target to run the python integration tests as the Virtual environment created by the 'mage' target does not install rust compiler automatically.
Rust compiler is required to install cryptography, which is a requirement to run python integration test cases.



