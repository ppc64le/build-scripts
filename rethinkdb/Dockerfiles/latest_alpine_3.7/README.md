How to use this image

Start an instance with data mounted in the working directory

The default CMD of the image is rethinkdb --bind all, so the RethinkDB daemon will bind to all network interfaces available to the container (by default, RethinkDB only accepts connections from localhost).
docker run --name some-rethink -v "$PWD:/data" -d ppc64le/rethinkdb


Connect the instance to an application
docker run --name some-app --link some-rethink:rdb -d application-that-uses-rdb


Connecting to the web admin interface on the same host
$BROWSER "http://$(docker inspect --format \
  '{{ .NetworkSettings.IPAddress }}' some-rethink):8080"


