Supported Tags

2.3.6


How to build this Dockerfile

docker build -t ibmcom/rethinkdb-ppc64le:<supported_tag>


How to use this image


Start an instance with data mounted in the working directory

The default CMD of the image is rethinkdb --bind all, so the RethinkDB daemon 
will bind to all network interfaces available to the container (by default, 
RethinkDB only accepts connections from localhost).

docker run --name some-rethink -v "$PWD:/data" -p 28015:28015 -p 29015:29015 -p 8080:8080 -d ibmcom/rethinkdb-ppc64le:<supported_tag>


Connect the instance to an application

docker run --name some-app --link some-rethink:rdb -d application-that-uses-rdb


Connecting to the web admin interface on the same host
$BROWSER "http://$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' some-rethink):8080"


Please note that <supported_tag> is one of the supported versions, as listed 
under the "Supported Tags" section and should be replaced as such.
