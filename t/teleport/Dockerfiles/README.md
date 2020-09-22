#The dockerfiles in this directory are derived from the community versions

#at https://github.com/gravitational/teleport


#Build steps are with respect to the same repository, so clone and add the ppc64le Dockerfile

#and follow the below steps

make docker

make image


#Running the image

mkdir -p ~/teleport/config ~/teleport/data

docker run --hostname localhost --rm   --entrypoint=/bin/sh   -v ~/teleport/config:/etc/teleport   quay.io/gravitational/teleport:4.3.6-dev.2 -c "teleport configure > /etc/teleport/teleport.yaml"

docker run --hostname localhost --name teleport   -v ~/teleport/config:/etc/teleport   -v ~/teleport/data:/var/lib/teleport   -p 3023:3023 -p 3025:3025 -p 3080:3080    quay.io/gravitational/teleport:4.3.6-dev.2
