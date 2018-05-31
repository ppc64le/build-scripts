Grizzly

Building and running the container

$ docker build -t grizzly .
$ docker run -it -p 8081:8080 grizzly

You will find all the jar files at "/grizzly/modules/grizzly/target/" inside the container.
This is a java framework, more info is found at:
 
https://javaee.github.io/grizzly/quickstart.html
