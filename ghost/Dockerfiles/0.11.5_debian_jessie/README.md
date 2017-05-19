
1) First create a docker image

	docker build -t ghost .

2) How to use this image :

	$ docker run --name some-ghost -d ghost
	This will start a Ghost instance listening on the default Ghost port of 2368.

	If you'd like to be able to access the instance from the host without the container's IP, standard port mappings can be used:

	$ docker run --name some-ghost -p 8080:2368 -d ghost
	Then, access it via http://localhost:8080 or http://host-ip:8080 in a browser. 


3) For more information please visit : https://hub.docker.com/_/ghost/
