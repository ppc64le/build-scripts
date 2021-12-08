Note - Files have be adapted from community dockerfiles available @ https://github.com/docker-library/docker/tree/835c371c516ebdf67adc0c76bbfb38bf9d3e586c/20.10

Docker build command:
docker build -t ppc64le/docker:20.10 .

Docker pull command:
docker pull ppc64le/docker:20.10

Sample Docker run command:
docker run -it -p some_port:2375 --privileged="true" --name=container_name docker 

Additional Details:
To start the docker service inside the container:
$service docker start

To run a sample image inside the container:
$docker run ppc64le/hello-world
