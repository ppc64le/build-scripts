# Fluentd is an open source data collector for unified logging layer

## Building the container image

`$ docker build -t fluentd .`

## Starting the container

`docker run -d --name fluent-logger --rm  -p 24224:24224 -p 24224:24224/udp -v ${pwd}/data:/fluentd/log fluentd:latest`

### Checking the container logs

`$ docker logs fluent-logger`

```console
2019-11-04 20:07:04 +0000 [info]: starting fluentd-1.7.4 pid=78 ruby="2.6.3"
2019-11-04 20:07:04 +0000 [info]: spawn command to main:  cmdline=["/home/fluentd/.rvm/rubies/ruby-2.6.3/bin/ruby", "-Eascii-8bit:ascii-8bit", "/home/fluentd/.rvm/gems/ruby-2.6.3/bin/fluentd", "-c", "/home/fluentd/fluent.conf", "-p", "/home/fluentd/plugin", "--under-supervisor"]
2019-11-04 20:07:05 +0000 [info]: gem 'fluentd' version '1.7.4'
2019-11-04 20:07:05 +0000 [info]: adding match in @mainstream pattern="docker.**" type="file"
2019-11-04 20:07:05 +0000 [info]: adding match in @mainstream pattern="**" type="file"
2019-11-04 20:07:05 +0000 [info]: adding filter pattern="**" type="stdout"
2019-11-04 20:07:05 +0000 [info]: adding source type="forward"
2019-11-04 20:07:05 +0000 [info]: #0 starting fluentd worker pid=81 ppid=78 worker=0
2019-11-04 20:07:05 +0000 [info]: #0 [input1] listening port port=24224 bind="0.0.0.0"
2019-11-04 20:07:05 +0000 [info]: #0 fluentd worker is now running worker=0
2019-11-04 20:07:05.181708615 +0000 fluent.info: {"worker":0,"message":"fluentd worker is now running worker=0"}
2019-11-04 20:07:05 +0000 [warn]: #0 no patterns matched tag="fluent.info"
```

## Test the container

### Find the ip address the container is using

`$ docker inspect -f '{{.NetworkSettings.IPAddress}}' fluent-logger`

```console
172.17.0.2
```

#### Use the ip address with the "_logging driver_"

`$ docker run --log-driver=fluentd --log-opt tag="docker.{{.ID}}" --log-opt fluentd-address=172.17.0.2:24224 python:alpine echo "Hello we using the logger"`

```console
Hello we using the logger
```

### Notes

* Listen port 24224 for Fluentd forward protocol
* Store logs with tag docker.** into /fluentd/log/docker.*.log (and symlink docker.log)
* Store all other logs into /fluentd/log/data.*.log (and symlink data.log)
* Make sure that folders given in -v options are present on your host and has correct permissions
