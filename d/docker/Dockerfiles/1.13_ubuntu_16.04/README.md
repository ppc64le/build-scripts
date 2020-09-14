Docker build command:
docker build -t ppc64le/docker:1.13.1

Docker pull command:
docker pull ppc64le/docker:1.13.1

Sample Docker run command:
docker run -it -p some_port:2375 --privileged="true" --name=container_name docker 

Additional Details:
To start the docker service inside the container:
$service docker start

To run a sample image inside the container:
$docker run ppc64le/hello-world
