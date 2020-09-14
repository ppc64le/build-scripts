Varnish-Cache

Building and running the container:

$ docker build -t varnish-cache .
$ docker run -it -p 8081:80 varnish-cache

Now you will be able to access the server from browser at:
http://vm_ip:8081

You will get an error on browser as "Backend fetch failed".
However this is expected, and will go if you link some container to it with some service running (Like nginx, httpd). 
You can provide your own conf file for starting varnishd while running container.

