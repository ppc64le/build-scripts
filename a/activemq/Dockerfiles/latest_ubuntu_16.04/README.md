ActiveMQ

Building and running the container

$ docker build -t activemq .
$ docker run -d -p 8161:8161 activemq

The activemq web console can be accessed using browser at:
http://vm_ip:8161

You can also give some other activemq command while running the container,
or even attach it using bash.
