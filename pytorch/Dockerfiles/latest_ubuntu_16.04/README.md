# Dockerfile README
The Dockerfile creates a container that builds and installs pytorch in a pytorch user environment. <br>
The base docker container is from https://hub.docker.com/r/nvidia/cuda-ppc64le (tag 9.0-cudnn7-devel-ubuntu16.04) <br>
The python (version 3.6) used is from Anaconda and is installed in /home/pytorch/miniconda <br>
The main script it executes is cloned from https://github.com/avmgithub/pytorch_builder.git <br>
The build_nimbix.sh also builds magma-cuda 2.3.0 from http://icl.utk.edu/projectsfiles/magma/downloads/magma-2.3.0.tar.gz <br>

There are 4 ENV variables that default to certain values. Feel free to change them as desired. <br>

+ ENV username=jenkins
+ ENV python_version=3
+ ENV git_commit=HEAD
+ ENV branch=master

# Instructions to build container
git clone https://github.com/ppc64le/build-scripts.git <br>
cd build-scripts/pytorch/Dockerfiles/latest_ubuntu_16.04 <br>
sudo docker build --tag="pytorch" . 

# Note
This supports CPU-only pytorch builds
