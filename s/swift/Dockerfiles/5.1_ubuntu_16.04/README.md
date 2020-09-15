# Apple Swift(v5.1) language compiler

Pre-requisites:-
-----------------------------------
The Swift installable package 'swift-LOCAL-YYYY-MM-DD-a-linux.tar.gz' built using 'swift51_ubuntu_16.04.sh' script should be copied from 'swift-source' directory to the same directory containing the Dockerfile and renamed to 'swift-5.1.tar.gz'.


Steps:-
-----------------------------------
1. Command to build Docker container:

   docker build --tag=swift-5.1 .

2. Command to create a container:

   docker run --cap-add=SYS_PTRACE --security-opt seccomp=unconfined --security-opt apparmor=unconfined -it --name swift-5.1_docker swift-5.1 /bin/bash

3. Once inside the container, swift compiler can be used as:

   swiftc --version
