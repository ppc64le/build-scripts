Description:

This dockerfile includes OpenJDK11, Maven, Helm, Buildah, and Open Shift Client.
  
Build & Usages :

To build the image,

1. copy the docker file to the location /home

2. use the below command to start building the image.  
docker build -t <IMAGE_NAME>:<TAG> <DOCKERFILE_LOCATION>

e.g. 
docker build -t multiapp:1.0 .

-t : to provide name & tag to building image, here "multiapp" is IMAGE NAME & "1.0" is a TAG provided to an image.
if the Dockerfile is kept at a location other than the building directory, provide the location in place of "."
See https://docs.docker.com/engine/reference/commandline/build/ for more information.

once the image is built, use the below command to check if the image is created successfully.

3. docker images <IMAGE_NAME>:<TAG>

e.g. 
docker images multiapp:1.0

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
multiapp            1.0                 baee380605f4        14 seconds ago      700 MB

4. then the command below can be used to create a container with the built image.
docker run --name <CONATAINER_NAME> -it <IMAGE_NAME>/<IMAGE_ID>

e.g. 
docker run --name testcontainer -it multiapp  OR
docker run --name testcontainer -it baee380605f4

--name: to provide the name of the container.
-it : to create an interactive container with a pseudo-TTY attached.

See https://docs.docker.com/engine/reference/commandline/run/ for more information.

this will create and run a container with a built image. 

More References :
https://docs.docker.com/

 
