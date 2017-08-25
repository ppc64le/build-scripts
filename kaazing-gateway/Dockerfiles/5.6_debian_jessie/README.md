How to use this image

You must give your gateway container a hostname. To do this, use the docker run -h somehostname option, along with the -e option to define an environment variable, 
GATEWAY_OPTS, to pass this hostname to the gateway configuration (your hostname may vary):
$ docker run --name some-kaazing-gateway -h somehostname -e GATEWAY_OPTS="-Dgateway.hostname=somehostname -Xmx512m -Djava.security.egd=file:/dev/urandom"-d -p 8000:8000 kaazing-gateway

Note: the additional GATEWAY_OPTS options, -Xmx512m -Djava.security.egd=file:/dev/urandom, 
are added in order to preserve these values from the original Dockerfile for the gateway. 

The -Xmx512m value specifies a minimum Java heap size of 512 MB, and -Djava.security.egd=file:/dev/urandom is to 
facilitate faster startup on VMs. 

You should then be able to connect to curl -I http://somehostname:8000 from the system.

Note: all of the above assumes that somehostname is resolvable from your browser. You may need to add an etc/hosts entry for somehostname on your dockerhost ip.
