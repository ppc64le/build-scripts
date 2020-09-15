
# Gerrit Code Review

This docker modules usesthe released Gerrit WAR. See <https://gerrit-releases.storage.googleapis.com/index.html>
and documentation here <https://gerrit-documentation.storage.googleapis.com/Documentation/3.0.3/index.html>

## Building the container image

`$ docker build -t gerrit .`

## Starting the container

`$ docker run -d -p 8080:8080 -p 29418:29418 gerrit:latest`

## Examine the container logs

`$ docker logs $(docker ps -lq)`

### Notes

Wait a few minutes until the Gerrit Code Review NNN ready message appears, where NNN is your current Gerrit version, then open your browser to <http://localhost:8080> and you will be in Gerrit Code Review.

A quick test can be done with curl.

`$ curl http://localhost:8080 --head`

```
HTTP/1.1 200 OK
Date: Thu, 31 Oct 2019 17:20:45 GMT
Set-Cookie: XSRF_TOKEN=;Path=/;Expires=Thu, 01-Jan-1970 00:00:00 GMT;Max-Age=0
Expires: Thu, 01 Jan 1970 00:00:00 GMT
Content-Type: text/html;charset=utf-8
Content-Length: 1480
```

If your docker server is running on a remote host, change 'localhost' to the hostname or IP address of your remote docker server.
