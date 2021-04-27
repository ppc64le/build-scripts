Base Image:

Note - Files have be adapted from community dockerfiles available @ https://github.com/docker-library/docker/tree/835c371c516ebdf67adc0c76bbfb38bf9d3e586c/19.03

We have used ppc64le/docker:19.03.13 as base image and its not published yet , so build ppc64le/docker:19.03.13 using Dockerfile available at https://github.com/ppc64le/build-scripts/tree/master/d/docker/19.03.13_centos8/Dockerfile

Docker build command:
docker build -t ppc64le/docker:dind-19.03.13

Docker pull command:
docker pull ppc64le/docker:dind-19.03.13

