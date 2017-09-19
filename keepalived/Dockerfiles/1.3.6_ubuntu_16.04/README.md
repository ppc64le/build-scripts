The Keepalived docker container can be built by following command - 

docker -H localhost:2255 build -t keepalived .

We can start the keepalived container by the following command - 

docker -H localhost:2255 run --privileged -v /lib/modules:/lib/modules -d keepalived  -it bash

Note - The container should be run on privileged mode only as it uses mod_probe which requires the permission to access kernal modules.
