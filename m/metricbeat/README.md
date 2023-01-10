To build and test metricbeat:

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
