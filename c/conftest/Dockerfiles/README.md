#To build the dockerfile use the below command


#Clone the source code

#git clone https://github.com/open-policy-agent/conftest -b v0.30.0


#Replace the existing Dockerfile with either the alpine or ubi based Dockerfiles present in the respect sub-folders of this folder


#Build the image using the below command

#docker build --build-arg ARCH=ppc64le --no-cache=true -t conftest-ppc64le .
